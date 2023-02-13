// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IDevSupply{
    function deposit(uint256 amount, address tokenAddress) external;
}

contract OGBToken is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor() ERC20("OGB Token", "OGB") {
        _mint(address(this), 1000000000*10**18);
    }

    function distribute(address devContract) public onlyOwner {
        //2.5% 
        uint256 devPercentage = 25*10**17; 

        //2.5% of totalSupply (1 Billion)
        uint256 devAmount = (totalSupply().mul(devPercentage))/10**20;

        //Approve devContract to send 2.5% of 1 Billion
        IERC20(address(this)).approve(devContract, devAmount);
        
        //2.5% send to devContract and start slicing
        IDevSupply(devContract).deposit(devAmount, address(this));
        
        IERC20(address(this)).safeTransfer(msg.sender, balanceOf(address(this)));
    }

    function burn(uint256 amount) public override {
        _burn(_msgSender(), amount);
    }
}



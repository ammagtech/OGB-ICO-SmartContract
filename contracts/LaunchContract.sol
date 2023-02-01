// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "./console.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface ILaunch{
    function Launch() external;
}

contract LaunchContract is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    
    constructor() {
        _disableInitializers();
    }

    address public seedAddress;
    address public round1Address;
    address public round2Address;
    bool private isLaunched;

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }
    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setContractAddresses(address _seedContract, address _round1) public onlyOwner {
        seedAddress = _seedContract;
        round1Address = _round1;
        //round2Address = _round2;
    }
    
    function LaunchToken() public onlyOwner{
        require(!isLaunched, "already launched");
        ILaunch(seedAddress).Launch();
        ILaunch(round1Address).Launch();
        //ILaunch(round2Address).Launch();
        isLaunched = true;
    }
    function chkLaunch() public view returns(bool){
        return isLaunched;
    }

    function emergencyWithdrawToken(address token, address destination) public onlyOwner returns (bool sent){
        IERC20(token).transfer(destination, IERC20(token).balanceOf(address(this)));
        return true;
    }

    function emergencyWithdrawCurrency(address destination) public onlyOwner returns (bool sent) {
        require(address(this).balance != 0, "ZERO_BALANCE");
        payable(destination).transfer(address(this).balance);
        return true;
    }

    receive() external payable {}

    fallback() external payable {}

}
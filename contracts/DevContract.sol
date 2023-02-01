// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract devContract is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    ///////////////////// Variables ///////////////////////
    using SafeMath for uint256;
    
    // mapping(address => bool) public isOperator;
    uint256 private lastWithdrawSlice;
    uint256 private lastWithdrawAmount;
    
    uint256 private lastSliceAmount;
    
    address public USDTAddress;
    address public OGBAddress;
    
    uint256 public noOfSlices;
    
    uint256 public perSlicePercentage;
    uint256 public devFee;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public cliff;
    
    uint256 public timePeriod;
    uint256 public sliceTime;
    uint256 public devContractBalance;

    bool public isTokenLaunch;


    event currentSliceStatus(uint256 _slice, uint256 _amount);

    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        devContractBalance = 25000000 * 10**18;
        lastSliceAmount = 10000 * 10**18;

        noOfSlices = 42;
        timePeriod = 12600;
        sliceTime = 300;
        
        cliff = block.timestamp + 360;

    }

    function setTokenAddress(address _OGBAddress) public onlyOwner{
        OGBAddress = _OGBAddress;
    }
    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}


    function deposit(uint256 _amount, address _OGBAddress) public {
        OGBAddress = _OGBAddress;
        require(OGBAddress == msg.sender, "you are not allowed");
        
        IERC20(OGBAddress).transferFrom(OGBAddress, address(this), _amount);
        isTokenLaunch = true;
        //Cliff
        startTime = block.timestamp + 360;
        endTime = startTime + timePeriod;
    }

    function getVestedAmount() public view returns(uint256 _vestedAmount, uint256 slice) {
        if(IERC20(OGBAddress).balanceOf(address(this)) > 0){
            (uint256 computedAmount, uint256 _slice) = _computeReleasableAmount();
            
            computedAmount = computedAmount.sub(lastWithdrawAmount);
            _vestedAmount = computedAmount; 
            
            slice = _slice;
        }
        else{
            _vestedAmount = 0;
            slice = noOfSlices + 1;
        }
    }

    function release() public onlyOwner {
        
        require(isTokenLaunch, "Token is not launched");
        
        (uint256 vestedAmount, uint256 slice) = getVestedAmount();

        if(slice > lastWithdrawSlice)
        {
            
            lastWithdrawSlice = slice;
            lastWithdrawAmount = lastWithdrawAmount.add(vestedAmount);
            
            IERC20(OGBAddress).transfer(msg.sender, vestedAmount);
            emit currentSliceStatus(slice, vestedAmount);
        }
        else{
            revert("You have already withdrawn the amount available");
        }
    }

    function _computeReleasableAmount() private view returns(uint256 _amount, uint256 _slicePasses){
        uint256 currentTime1 = block.timestamp; 
        uint256 timePassed;
        uint256 _amountToHold = devContractBalance - lastSliceAmount;

       
        if(currentTime1 >= cliff){
        
            if (currentTime1 >= endTime + sliceTime) {
                return (devContractBalance , noOfSlices + 1);
            }
            else if(currentTime1 < startTime){
                _amount =0; _slicePasses = 0;
            }
            else
            {
                timePassed = currentTime1.sub(startTime);
                uint256 NumberOfSlicesPassed = timePassed.div(sliceTime);
                
                if(NumberOfSlicesPassed > noOfSlices){
                    
                    
                    _amount = devContractBalance; _slicePasses = noOfSlices+1;
                    
                }
                else{
                    
                    uint256 amountPerSlice = (_amountToHold).div(noOfSlices);
                    
                    _amount = amountPerSlice.mul(NumberOfSlicesPassed); 
                    
                    _slicePasses = NumberOfSlicesPassed;

                    
                }
            }
        }
        else{
            _amount = 0;
            _slicePasses = 0;
        }
    }

    function V_GetRemaingTime() public view returns(uint remaingTime, uint sliceNum){
        
        uint256 currentTime = block.timestamp; 
        if(currentTime > cliff){
            if(currentTime <= startTime){
                //uint256 perSliceTime = timePeriodInSeconds.div(vestingSchedule.numberOfSlices);
                remaingTime = startTime.sub(currentTime);
                sliceNum = 0; 
            }
            else{
                
                if(currentTime >= endTime + sliceTime){
                    
                    remaingTime=0; sliceNum = noOfSlices + 1;
                }
                else{

                    uint256 timePassed = currentTime.sub(startTime);
                    
                    uint256 NumberOfSlicesPassed = timePassed.div(sliceTime);
                    
                    //uint256 perSliceTime = (endTime - startTime).div(noOfSlices);
                    
                    uint256 remainTime = ((NumberOfSlicesPassed+1).mul(sliceTime)).sub((timePassed));
                    
                    remaingTime=remainTime; sliceNum = NumberOfSlicesPassed;
                }
            }
        }
        else{
            remaingTime = cliff - currentTime;
            sliceNum = 0;
        }
    }

    function getTokenBalance(address _tokenAddress) public view returns(uint256 _tokenAmount){
        _tokenAmount = IERC20(_tokenAddress).balanceOf(address(this));
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
    
    function setOGBTAddress(address _OGBAddress) public onlyOwner{
        OGBAddress = _OGBAddress;
    }

    function setUSDTAddress(address _USDTAddress) public onlyOwner{
        USDTAddress = _USDTAddress;
    }


    receive() external payable {}

    fallback() external payable {}
}

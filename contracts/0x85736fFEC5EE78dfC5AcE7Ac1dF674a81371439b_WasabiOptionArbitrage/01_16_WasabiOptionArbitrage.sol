// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./IWasabiPool.sol";
import "./lib/Signing.sol";
import { IPool } from "./aave/IPool.sol";
import { IWETH } from "./aave/IWETH.sol";
import { IPoolAddressesProvider } from "./aave/IPoolAddressesProvider.sol";
import { IFlashLoanSimpleReceiver } from "./aave/IFlashLoanSimpleReceiver.sol";

/**
  * An arbitrage contract that takes a flash loan, exercises an option and buys/sells from the marketplaces
  * to take profits without using any user capital.
  */
contract WasabiOptionArbitrage is IERC721Receiver, Ownable, ReentrancyGuard, IFlashLoanSimpleReceiver {
    address private option;
    address private addressProvider;
    address wethAddress;

    error FailedToExecuteMarketOrder();

    struct FunctionCallData {
        address to;
        uint256 value;
        bytes data;
    }

    IPool private lendingPool;

    event Arbitrage(address account, uint256 optionId, uint256 payout);

    /**
     * @dev Constructs a new WasabiOptionArbitrage contract
     */
    constructor(address _option, address _addressProvider, address _wethAddress) {
        option = _option;
        addressProvider = _addressProvider;
        wethAddress = _wethAddress;
        lendingPool = IPool(IPoolAddressesProvider(addressProvider).getPool());
    }

    /**
     * @dev Executes the given option and takes profits by selling/buying from the markets for the given marketplace call data
     */
    function arbitrage(
        uint256 _optionId,
        uint256 _value,
        address _poolAddress,
        uint256 _tokenId,
        FunctionCallData[] calldata _marketplaceCallData,
        bytes[] calldata _signatures
    ) external payable nonReentrant {
        validate(_marketplaceCallData, _signatures);
        // Transfer Option for Execute
        IERC721(option).safeTransferFrom(msg.sender, address(this), _optionId);

        address asset = IWasabiPool(_poolAddress).getLiquidityAddress();
        if (asset == address(0)) {
            asset = wethAddress;
        }

        uint16 referralCode = 0;
        bytes memory params = abi.encode(_optionId, _poolAddress, _tokenId, _marketplaceCallData);

        lendingPool.flashLoanSimple(address(this), asset, _value, params, referralCode);

        uint256 wBalance = IWETH(wethAddress).balanceOf(address(this));
        if (wBalance != 0) {
            IWETH(wethAddress).withdraw(wBalance);
        }
        
        uint256 balance = address(this).balance;
        if (balance != 0) {
            (bool sent, ) = payable(msg.sender).call{value: balance}("");
            require(sent, "Failed to send Ether");
        }
    }

    /**
     * @dev Executes the arbitrage operation
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address,
        bytes calldata params
    ) external override returns(bool) {
        ( uint256 _optionId, address _poolAddress, uint256 _tokenId, FunctionCallData[] memory _calldataList ) =
            abi.decode(params, (uint256, address, uint256, FunctionCallData[]));

        IWasabiPool pool = IWasabiPool(_poolAddress);
        address nft = IWasabiPool(_poolAddress).getNftAddress();

        // Validate Order
        IWETH(asset).withdraw(amount);
        uint256 totalDebt = amount + premium;

        if (pool.getOptionData(_optionId).optionType == WasabiStructs.OptionType.CALL) {
            // Execute Option
            IWasabiPool(_poolAddress).executeOption{value: amount}(_optionId);

            // Sell NFT
            bool marketSuccess = executeFunctions(_calldataList);
            if (!marketSuccess) {
                return false;
            }
        } else {
            // Purchase NFT
            bool marketSuccess = executeFunctions(_calldataList);
            if (!marketSuccess) {
                return false;
            }

            //Execute Option
            IERC721(nft).approve(_poolAddress, _tokenId);
            IWasabiPool(_poolAddress).executeOptionWithSell(_optionId, _tokenId);
            
            IWETH(wethAddress).deposit{value: totalDebt}();
        }
        
        IWETH(asset).approve(address(lendingPool), totalDebt);

        return true;
    }

    /**
     * @dev Executes a given list of functions
     */
    function executeFunctions(FunctionCallData[] memory _marketplaceCallData) internal returns (bool) {
        for (uint256 i = 0; i < _marketplaceCallData.length; i++) {
            FunctionCallData memory functionCallData = _marketplaceCallData[i];
            (bool success, ) = functionCallData.to.call{value: functionCallData.value}(functionCallData.data);
            if (success == false) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Validates if the FunctionCallData list has been approved
     */
    function validate(FunctionCallData[] calldata _marketplaceCallData, bytes[] calldata _signatures) private view {
        require(_marketplaceCallData.length == _signatures.length, "Length is invalid");
        for (uint256 i = 0; i < _marketplaceCallData.length; i++) {
            bytes32 ethSignedMessageHash = Signing.getEthSignedMessageHash(getMessageHash(_marketplaceCallData[i]));
            require(Signing.recoverSigner(ethSignedMessageHash, _signatures[i]) == owner(), 'Owner is not signer');
        }
    }

    /**
     * @dev Returns the message hash for the given _data
     */
    function getMessageHash(FunctionCallData calldata _data) public pure returns (bytes32) {
        return keccak256(abi.encode(_data.to, _data.value, _data.data));
    }
    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 /* tokenId */,
        bytes memory /* data */)
    public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    // Payable function to receive ETH
    receive() external payable {
    }

    /**
     * @dev withdraws any stuck eth in this contract
     */
    function withdrawETH(uint256 _amount) external payable onlyOwner {
        require(_amount <= address(this).balance, 'Invalid amount');
        address payable to = payable(owner());
        to.transfer(_amount);
    }

    /**
     * @dev withdraws any stuck ERC20 in this contract
     */
    function withdrawERC20(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    /**
     * @dev withdraws any stuck ERC721 in this contract
     */
    function withdrawERC721(IERC721 _token, uint256 _tokenId) external onlyOwner {
        _token.safeTransferFrom(address(this), owner(), _tokenId);
    }
}
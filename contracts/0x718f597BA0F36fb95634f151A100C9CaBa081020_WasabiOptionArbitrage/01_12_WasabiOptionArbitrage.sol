// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./IWasabiPool.sol";
import "./lib/Signing.sol";
import { IWETH } from "./IWETH.sol";

/**
  * An arbitrage contract that exercises an option and buys/sells from the marketplaces
  * to take profits without using any user capital.
  */
contract WasabiOptionArbitrage is IERC721Receiver, Ownable, ReentrancyGuard {
    address private option;
    address wethAddress;
    uint256 loanPremiumValue;
    uint256 loanPremiumFraction;

    error FailedToExecuteMarketOrder();

    struct FunctionCallData {
        address to;
        uint256 value;
        bytes data;
    }


    event Arbitrage(address account, uint256 optionId, uint256 payout);

    /**
     * @dev Constructs a new WasabiOptionArbitrage contract
     */
    constructor(address _option, address _wethAddress) {
        option = _option;
        wethAddress = _wethAddress;
        loanPremiumValue = 9;
        loanPremiumFraction = 10_000; // 0.09%
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

        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= _value, "Requested amount exceeds balance");

        // Transfer Option for Execute
        IERC721(option).safeTransferFrom(msg.sender, address(this), _optionId);

        IWasabiPool pool = IWasabiPool(_poolAddress);

        require(pool.getLiquidityAddress() == address(0), "Cannot perform arbitrage for non ETH pools");

        uint256 loanPremium = _value * loanPremiumValue / loanPremiumFraction;

        WasabiStructs.OptionData memory optionData = pool.getOptionData(_optionId);
        if (optionData.optionType == WasabiStructs.OptionType.CALL) {
            // Execute Option
            IWasabiPool(_poolAddress).executeOption{value: _value}(_optionId);

            // Sell NFT
            bool marketSuccess = executeFunctions(_marketplaceCallData);
            if (!marketSuccess) {
                revert FailedToExecuteMarketOrder();
            }

            // Withdraw any WETH received
            IWETH weth = IWETH(wethAddress);
            uint256 wethBalance = weth.balanceOf(address(this));
            if (wethBalance > 0) {
                weth.withdraw(wethBalance);
            }
        } else {
            // Buy NFT
            bool marketSuccess = executeFunctions(_marketplaceCallData);
            if (!marketSuccess) {
                revert FailedToExecuteMarketOrder();
            }

            // Execute Option
            address nft = IWasabiPool(_poolAddress).getNftAddress();
            IERC721(nft).approve(_poolAddress, _tokenId);
            IWasabiPool(_poolAddress).executeOptionWithSell(_optionId, _tokenId);
        }

        require(address(this).balance >= balanceBefore + loanPremium, "Loan not paid back");
        uint256 payout = address(this).balance - balanceBefore - loanPremium;

        (bool sent, ) = payable(_msgSender()).call{value: payout}("");
        require(sent, "Failed to send ETH");

        emit Arbitrage(_msgSender(), _optionId, payout);
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
        require(_marketplaceCallData.length > 0, "Need marketplace calls");
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

    /**
     * @dev sets the loan premium value
     */
    function setLoanPremiumValue(uint256 _loanPremiumValue) external onlyOwner {
        loanPremiumValue = _loanPremiumValue;
    }
}
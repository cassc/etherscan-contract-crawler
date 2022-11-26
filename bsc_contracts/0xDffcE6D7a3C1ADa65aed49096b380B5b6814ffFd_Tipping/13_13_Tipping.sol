// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import { ITipping } from "./interfaces/ITipping.sol";
import { MultiAssetSender } from "./libs/MultiAssetSender.sol";
import { FeeCalculator } from "./libs/FeeCalculator.sol";
import { Batchable } from "./libs/Batchable.sol";

import { AssetType, FeeType } from "./enums/IDrissEnums.sol";

error tipping__withdraw__OnlyAdminCanWithdraw();

/**
 * @title Tipping
 * @author Lennard (lennardevertz)
 * @custom:contributor Rafał Kalinowski <[email protected]>
 * @notice Tipping is a helper smart contract used for IDriss social media tipping functionality
 */
contract Tipping is Ownable, ITipping, MultiAssetSender, FeeCalculator, Batchable, IERC165 {
    address public contractOwner;
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public admins;

    event TipMessage(
        address indexed recipientAddress,
        string message,
        address indexed sender,
        address indexed tokenAddress
    );

    constructor(address _maticUsdAggregator) FeeCalculator(_maticUsdAggregator) {
        admins[msg.sender] = true;

        FEE_TYPE_MAPPING[AssetType.Coin] = FeeType.Percentage;
        FEE_TYPE_MAPPING[AssetType.Token] = FeeType.Percentage;
        FEE_TYPE_MAPPING[AssetType.NFT] = FeeType.Constant;
        FEE_TYPE_MAPPING[AssetType.ERC1155] = FeeType.Constant;
    }

    /**
     * @notice Send native currency tip, charging a small fee
     */
    function sendTo(
        address _recipient,
        uint256, // amount is used only for multicall
        string memory _message
    ) external payable override {
        uint256 msgValue = _MSG_VALUE > 0 ? _MSG_VALUE : msg.value;
        (, uint256 paymentValue) = _splitPayment(msgValue, AssetType.Coin);
        _sendCoin(_recipient, paymentValue);

        emit TipMessage(_recipient, _message, msg.sender, address(0));
    }

    /**
     * @notice Send a tip in ERC20 token, charging a small fee
     */
    function sendTokenTo(
        address _recipient,
        uint256 _amount,
        address _tokenContractAddr,
        string memory _message
    ) external payable override {
        (, uint256 paymentValue) = _splitPayment(_amount, AssetType.Token);

        _sendTokenAssetFrom(_amount, msg.sender, address(this), _tokenContractAddr);
        _sendTokenAsset(paymentValue, _recipient, _tokenContractAddr);

        emit TipMessage(_recipient, _message, msg.sender, _tokenContractAddr);
    }

    /**
     * @notice Send a tip in ERC721 token, charging a small $ fee
     */
    function sendERC721To(
        address _recipient,
        uint256 _tokenId,
        address _nftContractAddress,
        string memory _message
    ) external payable override {
        // we use it just to revert when value is too small
        uint256 msgValue = _MSG_VALUE > 0 ? _MSG_VALUE : msg.value;
        _splitPayment(msgValue, AssetType.NFT);

        _sendNFTAsset(_tokenId, msg.sender, _recipient, _nftContractAddress);

        emit TipMessage(_recipient, _message, msg.sender, _nftContractAddress);
    }

    /**
     * @notice Send a tip in ERC721 token, charging a small $ fee
     */
    function sendERC1155To(
        address _recipient,
        uint256 _assetId,
        uint256 _amount,
        address _assetContractAddress,
        string memory _message
    ) external payable override {
        // we use it just to revert when value is too small
        uint256 msgValue = _MSG_VALUE > 0 ? _MSG_VALUE : msg.value;
        _splitPayment(msgValue, AssetType.ERC1155);

        _sendERC1155Asset(_assetId, _amount, msg.sender, _recipient, _assetContractAddress);

        emit TipMessage(_recipient, _message, msg.sender, _assetContractAddress);
    }

    /**
     * @notice Withdraw native currency transfer fees
     */
    function withdraw() external override onlyAdminCanWithdraw {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to withdraw.");
    }

    modifier onlyAdminCanWithdraw() {
        if (admins[msg.sender] != true) {
            revert tipping__withdraw__OnlyAdminCanWithdraw();
        }
        _;
    }

    /**
     * @notice Withdraw ERC20 transfer fees
     */
    function withdrawToken(address _tokenContract)
        external
        override
        onlyAdminCanWithdraw
    {
        IERC20 withdrawTC = IERC20(_tokenContract);
        withdrawTC.transfer(msg.sender, withdrawTC.balanceOf(address(this)));
    }

    /**
     * @notice Add admin with priviledged access
     */
    function addAdmin(address _adminAddress)
        external
        override
        onlyOwner
    {
        admins[_adminAddress] = true;
    }

    /**
     * @notice Remove admin
     */
    function deleteAdmin(address _adminAddress)
        external
        override
        onlyOwner
    {
        admins[_adminAddress] = false;
    }

    /**
    * @notice This is a function that allows for multicall
    * @param _calls An array of inputs for each call.
    * @dev calls Batchable::callBatch
    */
    function batch(bytes[] calldata _calls) external payable {
        batchCall(_calls);
    }

    function isMsgValueOverride(bytes4 _selector) override pure internal returns (bool) {
        return
            _selector == this.sendTo.selector ||
            _selector == this.sendTokenTo.selector ||
            _selector == this.sendERC721To.selector ||
            _selector == this.sendERC1155To.selector
        ;
    }

    function calculateMsgValueForACall(bytes4 _selector, bytes memory _calldata) override view internal returns (uint256) {
        uint256 currentCallPriceAmount;

        if (_selector == this.sendTo.selector) {
            assembly {
                currentCallPriceAmount := mload(add(_calldata, 68))
            }
        } else if (_selector == this.sendTokenTo.selector) {
            currentCallPriceAmount = getPaymentFee(0, AssetType.Token);
        } else if (_selector == this.sendTokenTo.selector) {
            currentCallPriceAmount = getPaymentFee(0, AssetType.NFT);
        } else {
            currentCallPriceAmount = getPaymentFee(0, AssetType.ERC1155);
        }

        return currentCallPriceAmount;
    }

    /*
    * @notice Always reverts. By default Ownable supports renouncing ownership, that is setting owner to address 0.
    *         However in this case it would disallow receiving payment fees by anyone.
    */
    function renounceOwnership() public override view onlyOwner {
        revert("Operation not supported");
    }

    /**
     * @notice ERC165 interface function implementation, listing all supported interfaces
     */
    function supportsInterface (bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId
         || interfaceId == type(ITipping).interfaceId;
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract Marketplace is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable{
    address public platformAddress;
    address public signerAddress;
    uint256 public chainId;

    mapping (address => mapping (uint256 => uint256)) public priceNFT;
    mapping (address => mapping (uint256 => bool)) public statusNFT;
    mapping (bytes32 => bool) private preventReplayAttack;

    struct Sig{bytes32 r; bytes32 s; uint8 v;}
    struct Buy{address nftAddress; address seller; address buyer; uint256 tokenID; string transactionID;address ipHolderAddr; uint256 percIpHolder; address projOwnAddr; uint256 percProjOwn; uint256 platformFee;}

    event CancelSellEvent(address Caller, address nftAddress, uint256 TokenID, string transactionID, uint256 TimeStamp);
    event ChangePriceEvent(address Caller, address nftAddress, uint256 TokenID, uint256 NewPrice, string transactionID, uint256 TimeStamp);
    event BuyPackEvent(address buyerAddress, uint256 packID, uint256 amountPack, uint256 transferredAmount, string transactionID, uint256 TimeStamp, bytes transferData);
    event SellEvent(address Caller, address nftAddress, uint256 TokenID, uint256 Price, string transactionID, uint256 TimeStamp);
    event BuyEvent(address Caller, address nftAddress, uint256 TokenID, uint256 Price, string transactionID, uint256 TimeStamp);
    event MintEvent(address Caller, string pointerMoment, uint256 TimeStamp);
    event SwapEvent(uint256[] fromTokenID, uint256[] toTokenID, address fromNFTAddress, address toNFTAddress, address callerAddress, address swapWallet, string transactionID);

    function initialize(address _signerAddress) public initializer {
        require(_signerAddress != address(0), "Init: ADDRES_SIGNER_INVALID");
        __Ownable_init();
        __ReentrancyGuard_init();
        signerAddress = _signerAddress;
        chainId = _getChainId();
    }

    function sell(address nftAddress, uint256 tokenID, uint256 price, string memory transactionID, Sig memory sellRSV) public nonReentrant onlyNFTOwner(nftAddress, tokenID){
        require(!getStatusNFT(nftAddress, tokenID), "Sell: NFT Already Listed!");
        bytes32 message = messageHash(abi.encodePacked(msg.sender, nftAddress, tokenID, price, transactionID, chainId, address(this)));
        checkReplayAttack(message);
        //TODO: add tokenID into RSV
        require(verifySigner(signerAddress, message, sellRSV), "Sell: RSV invalid");
        setStatusNFT(nftAddress, tokenID, true);
        setPriceNFT(nftAddress, tokenID, price);
        emit SellEvent(msg.sender, nftAddress, tokenID, price, transactionID, block.timestamp);
    }

    function buy(Buy memory buyStruct, Sig memory buyRSV, uint256 totalFee) public payable nonReentrant  {
        require(getStatusNFT(buyStruct.nftAddress, buyStruct.tokenID), "Buy: NFT is not listed!");
        bytes32 message = messageHash(abi.encodePacked(buyStruct.buyer, buyStruct.seller, buyStruct.nftAddress, buyStruct.tokenID, msg.value, buyStruct.transactionID, buyStruct.percIpHolder, buyStruct.ipHolderAddr, buyStruct.percProjOwn, buyStruct.projOwnAddr,buyStruct.platformFee, totalFee, chainId, address(this)));
        checkReplayAttack(message);
        require(verifySigner(signerAddress, message, buyRSV), "Buy: RSV invalid");
        uint256 price = getPriceNFT(buyStruct.nftAddress, buyStruct.tokenID);
        require(price + totalFee == msg.value, "Buy: MSG_VALUE is not match with listing price!");
        require(buyStruct.seller != buyStruct.buyer, "Buy: You can't buy your own NFT!");
        setStatusNFT(buyStruct.nftAddress, buyStruct.tokenID, false);
        uint fee0 = price * buyStruct.platformFee / 10000;
        uint fee1 = price * buyStruct.percIpHolder / 10000;
        uint fee2 = price * buyStruct.percProjOwn / 10000;
        safeTransferETH(platformAddress, fee0);
        safeTransferETH(buyStruct.ipHolderAddr, fee1);
        safeTransferETH(buyStruct.projOwnAddr, fee2);
        setPriceNFT(buyStruct.nftAddress, buyStruct.tokenID, 0);
        if(totalFee == 0) {
            safeTransferETH(buyStruct.seller,  (msg.value * (10000 - (buyStruct.platformFee + buyStruct.percIpHolder + buyStruct.percProjOwn))) / 10000);
        }else{
            require(totalFee == (fee0 + fee1 + fee2), "Fee paid mismatch with totalfee");
            safeTransferETH(buyStruct.seller, price);
        }
        ERC721Upgradeable(buyStruct.nftAddress).safeTransferFrom(buyStruct.seller, buyStruct.buyer, buyStruct.tokenID);
        emit BuyEvent(buyStruct.buyer, buyStruct.nftAddress, buyStruct.tokenID, msg.value, buyStruct.transactionID, block.timestamp);
    }

    function cancelSell(address nftAddress, uint256 tokenID, string memory transactionID, Sig memory cancelRSV) public nonReentrant onlyNFTOwner(nftAddress, tokenID) {
        bytes32 message = messageHash(abi.encodePacked(msg.sender, nftAddress, tokenID, transactionID, chainId, address(this)));
        checkReplayAttack(message);
        require(verifySigner(signerAddress, message, cancelRSV), "CancelSell: RSV invalid");
        require(getStatusNFT(nftAddress, tokenID), "CancelSell: NFT is not listed!");
        setPriceNFT(nftAddress, tokenID, 0);
        setStatusNFT(nftAddress, tokenID, false);
        emit CancelSellEvent(msg.sender, nftAddress, tokenID, transactionID, block.timestamp);
    }
    
    function changePrice(address nftAddress, uint256 tokenID, uint256 newPrice, string memory transactionID, Sig memory changePriceRSV) public nonReentrant onlyNFTOwner(nftAddress, tokenID) {
        bytes32 message = messageHash(abi.encodePacked(msg.sender, nftAddress, tokenID, newPrice, transactionID, chainId, address(this)));
        checkReplayAttack(message);
        require(verifySigner(signerAddress, message, changePriceRSV), "ChangePrice: RSV invalid");
        require(getStatusNFT(nftAddress, tokenID), "ChangePrice: You can't change price NFT that not selled!");
        setPriceNFT(nftAddress, tokenID, newPrice);
        emit ChangePriceEvent(msg.sender, nftAddress, tokenID, newPrice, transactionID, block.timestamp);
    }
    function safeTransferETH(address to, uint256 value) internal {
        checkValidAddress(to);
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }

    function updatePlatform(address newPlatform) external onlyOwner  {
        checkValidAddress(newPlatform);
        platformAddress = newPlatform;
    }

    function updateSigner(address newSigner) external onlyOwner  {
        checkValidAddress(newSigner);
        signerAddress = newSigner;
    }
    //Code below is from storage
    function setPriceNFT(address nftAddress, uint256 tokenID, uint256 price) internal {
        priceNFT[nftAddress][tokenID] = price;
    }
    function getPriceNFT(address nftAddress, uint256 tokenID) public view returns(uint256) {
        return priceNFT[nftAddress][tokenID];
    }
    function setStatusNFT(address nftAddress, uint256 tokenID, bool status) internal {
        statusNFT[nftAddress][tokenID] = status;
    }
    function getStatusNFT(address nftAddress, uint256 tokenID) public view returns(bool){
        return statusNFT[nftAddress][tokenID];
    }

    function checkReplayAttack(bytes32 message) public {
        require(!preventReplayAttack[message],"Message is already used!");
        preventReplayAttack[message] = true;
    }

    function checkValidAddress(address checked) private pure {
        require(checked != address(0), "Address invalid");
    }

    function verifySigner(address signer, bytes32 ethSignedMessageHash, Sig memory rsv) internal pure returns (bool)
    {
        return ECDSAUpgradeable.recover(ethSignedMessageHash, rsv.v, rsv.r, rsv.s) == signer;
    }

    function messageHash(bytes memory abiEncode)internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abiEncode)));
    }

    function _getChainId() private view returns (uint256 chainID) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainID := chainid()
        }
    }

    modifier onlyNFTOwner(address nftAddress, uint256 tokenID) {
        require(ERC721Upgradeable(nftAddress).ownerOf(tokenID) == msg.sender, "You're not an owner of this NFT");
        _;
    }
}
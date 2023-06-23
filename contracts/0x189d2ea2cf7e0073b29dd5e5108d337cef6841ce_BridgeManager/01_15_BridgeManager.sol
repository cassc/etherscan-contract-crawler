//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.15;

import "./NFT.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BridgeManager is Ownable {

    using ECDSA for BridgeManager;


    uint public fee = 5e18; // 5$
    address public payment_account = msg.sender;

    AggregatorInterface public chainlinkRef = AggregatorInterface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e); // bsc testnet

    mapping(address => mapping(uint => uint)) public nonces;

    NFT[] collections;
    mapping(address => bool) public is_minted;

    event Mint_Collection(address addr, string name, string symbol, string baseURI, string stacksAddress);
    event Bridge2Eth(address collection, string collection_stx, uint tokenId, bool takeFee, uint nonce);
    event Bridge2Stacks(address collection_eth, string collection_stx, uint tokenId, string dstAddress, bool takeFee, uint nonce);
    event SetFee(uint fee);
    event SetPaymentAccount(address paymentAccount);
    
    function mint_collection(string memory name, string memory symbol, string memory baseURI, string memory stacksAddress) external onlyOwner {
        NFT collection = new NFT(name, symbol, baseURI, stacksAddress);
        collections.push(collection);
        is_minted[address(collection)] = true;
        emit Mint_Collection(address(collection), name, symbol, baseURI, stacksAddress);
    }

    function get_collections() external view returns(NFT[] memory){
        return collections;
    }

    function bridge2Eth(NFT collection, uint256 tokenId, uint takeFee, bytes memory signature) external payable {
        require(is_minted[address(collection)], "Invalid collection address");
        bytes memory message = abi.encodePacked(msg.sender, address(this), address(collection), tokenId, takeFee, nonces[address(collection)][tokenId]);
        bytes32 msgHash = ECDSA.toEthSignedMessageHash(keccak256(message));
        (address signer, ) = ECDSA.tryRecover(msgHash, signature);
        uint eth_fee = 0;
        if(takeFee == 1) {
            eth_fee = fee * 1e8 / chainlinkRef.latestAnswer();
        }
        require(signer == owner(), "Not signed by owner");
        require(msg.value >= eth_fee, "Must pay fee");
        if(msg.value > eth_fee)
            payable(msg.sender).transfer(msg.value - eth_fee);
        if(eth_fee > 0) 
            payable(payment_account).transfer(eth_fee);
        if(collection.exists(tokenId))
            collection.transferFrom(address(this), msg.sender, tokenId);
        else
            collection.mint(msg.sender, tokenId);
        emit Bridge2Eth(address(collection), collection.stacksAddress(), tokenId, takeFee == 1, nonces[address(collection)][tokenId] ++);
    }

    function bridge2Stacks(NFT collection, uint256 tokenId, bool takeFee, string memory dstAddress) external payable {
        require(is_minted[address(collection)], "Invalid collection address");
        uint eth_fee = 0;
        if(takeFee) {
            eth_fee = fee * 1e8 / chainlinkRef.latestAnswer();
        }
        require(msg.value >= eth_fee, "Must pay fee");
        if(msg.value > eth_fee)
            payable(msg.sender).transfer(msg.value - eth_fee);
        if(eth_fee > 0)
            payable(payment_account).transfer(eth_fee);
        collection.bridge2Stacks(msg.sender, tokenId);  
        emit Bridge2Stacks(address(collection), collection.stacksAddress(), tokenId, dstAddress, takeFee, nonces[address(collection)][tokenId] ++);
    }

    function setFee(uint fee_) external onlyOwner {
        fee = fee_;
        emit SetFee(fee_);
    }

    function set_payment_account(address payment_account_) external onlyOwner {
        payment_account = payment_account_;
        emit SetPaymentAccount(payment_account_);
    }
    
}
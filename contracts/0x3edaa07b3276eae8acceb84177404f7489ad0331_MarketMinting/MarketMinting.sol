/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.8.0 <0.9.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// File: contracts/standards/ERC165.sol



pragma solidity >=0.8.0 <0.9.0;


abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}


contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
// File: contracts/interfaces/IERC2981.sol



pragma solidity ^0.8.0;


interface IERC2981 is IERC165 {
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


interface IERC721VirtualAsset is IERC721, IERC2981 {
     function mintTo(address _to, address _royaltyReceiver)  external;
     function mintTo(address _to, address _royaltyReceiver, bytes memory data)  external;
}

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


interface IERC1155VirtualAsset is IERC1155 {
    function mintTo( address _to, uint256 _tokenId, uint256 _amount)  external;
    function mintTo( address _to, uint256 _tokenId, uint256 _amount, bytes memory data)  external;
}

library Counters {
    struct Counter {
        uint256 _value;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

contract TokenAccessControl {
    bool public paused = false;
    address public owner;
    address public newContractOwner;
    mapping(address => bool) public authorizedContracts;

    event Pause();
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier ifNotPaused() {
        require(!paused, "contract is paused");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not an owner");
        _;
    }

    modifier onlyAuthorizedUser() {
        require(
            authorizedContracts[msg.sender],
            "caller is not an authorized user"
        );
        _;
    }

    modifier onlyOwnerOrAuthorizedUser() {
        require(
            authorizedContracts[msg.sender] || msg.sender == owner,
            "caller is not an authorized user or an owner"
        );
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newContractOwner = _newOwner;
    }

    function acceptOwnership() public ifNotPaused {
        require(msg.sender == newContractOwner);
        emit OwnershipTransferred(owner, newContractOwner);
        owner = newContractOwner;
        newContractOwner = address(0);
    }

    function setAuthorizedUser(
        address _operator,
        bool _approve
    ) public onlyOwner {
        if (_approve) {
            authorizedContracts[_operator] = true;
        } else {
            delete authorizedContracts[_operator];
        }
    }

    function setPause(bool _paused) public onlyOwner {
        paused = _paused;
        if (paused) {
            emit Pause();
        }
    }
}

contract MarketMinting is TokenAccessControl, ERC1155Holder, ERC721Holder {
    using Counters for Counters.Counter;
    struct Offer {
        address nftAddress;
        uint256 nftTokenId; // 0 for erc721
        uint256 amount; // always 1 for erc721
        address paymentTokenAddress;
        uint256 price;
        uint256 fee;
        address seller;
        address buyer;
        address royaltyReceiver;
        uint createdAtBlock;
        bytes nftRawData;
    }
    Counters.Counter private offerId;
    mapping(uint256 => Offer) offers;

    uint _offerValidityBlocks = 100;
   
    bytes4 constant private IERC165_ID = 0x01ffc9a7;
    bytes4 constant private IERC1155_ID = 0xd9b67a26;
    bytes4 constant private IERC721_ID = 0x80ac58cd;
    bytes4 constant private IERC2981_ID = 0x2a55205a;

    event CreateMarketMintingOffer(uint256 indexed offerId, address nftAddress, uint256 nftTokenId, uint256 amount,
     address paymentTokenAddress, uint256 price, uint256 fee, address seller, address buyer, address royaltyReceiver, bytes rawNftData);
    event BuyMarketMintingOffer(uint256 indexed offerId, address nftAddress, uint256 nftTokenId,
     uint256 amount, address paymentTokenAddress, uint256 price, address seller, address buyer, address royaltyReceiver);
    event CancelMarketMintingOffer(uint256 indexed offerId, address nftAddress, uint256 nftTokenId, uint256 amount, address seller, address buyer);
    event RoyaltyPayment(address from, address indexed to, address indexed tokenAddress, uint256 indexed amount, address nftAddress, uint256 tokenId);


    constructor(){
        offerId._value=300;
    }
    
    function createOffer(address nftAddress, uint256 nftTokenId, uint256 amount, address paymentTokenAddress,
     uint256 price, uint256 fee, address seller, address buyer, address royaltyReceiver, bytes memory rawNftData) external onlyOwner returns (uint256 _offerId) {
        offerId.increment();
        require(price>0, "Market: price should be greater than 0");
        require(fee>=0, " Market: fee cannot be negative");
        require(fee<price, "Market: fee cannot be greater than price");
        offers[offerId.current()] = Offer(nftAddress, nftTokenId, amount, paymentTokenAddress, price, fee, seller, buyer, royaltyReceiver, block.number, rawNftData);

        emit CreateMarketMintingOffer(offerId.current(), nftAddress, nftTokenId, amount, paymentTokenAddress, price, fee,  seller, buyer, royaltyReceiver,
        rawNftData);
        return offerId.current();
    }

    function buyOffer(uint256 _offerId) external payable {
        Offer memory offer = offers[_offerId];
        require(offer.seller != address(0), "Market: offer is not valid");
        require(offer.buyer == msg.sender, "Market: you are not eligible to buy this offer");
        require(offer.createdAtBlock+_offerValidityBlocks >= block.number, "Market: offer is not valid");
        delete offers[_offerId];
        uint256 royaltyAmount = 0;
        address royaltyReceiver = address(0);
        uint256 priceAfterFee = offer.price - offer.fee;

        if(IERC165(offer.nftAddress).supportsInterface(IERC1155_ID)){
            if(offer.nftRawData.length == 0){
                IERC1155VirtualAsset(offer.nftAddress).mintTo(msg.sender, offer.nftTokenId, offer.amount);
            }
            else{
                IERC1155VirtualAsset(offer.nftAddress).mintTo(msg.sender, offer.nftTokenId, offer.amount, offer.nftRawData);
            }
        }
        else{
            if(offer.nftRawData.length == 0){
                IERC721VirtualAsset(offer.nftAddress).mintTo(msg.sender, offer.royaltyReceiver);
            }
            else{
                IERC721VirtualAsset(offer.nftAddress).mintTo(msg.sender, offer.royaltyReceiver, offer.nftRawData);
            }
        }

        (royaltyReceiver, royaltyAmount) = getRoyaltyInfo(offer.nftAddress, offer.nftTokenId, priceAfterFee);
        
        if(offer.paymentTokenAddress!=address(0)){
            IERC20(offer.paymentTokenAddress).transferFrom(msg.sender, offer.seller, priceAfterFee-royaltyAmount);
            if(royaltyAmount != 0){
                IERC20(offer.paymentTokenAddress).transferFrom(msg.sender, royaltyReceiver, royaltyAmount);
                emit RoyaltyPayment(msg.sender, royaltyReceiver, offer.paymentTokenAddress, royaltyAmount, offer.nftAddress,
                offer.nftTokenId);
            }
            if(offer.fee!=0){
                IERC20(offer.paymentTokenAddress).transferFrom(msg.sender, address(this), offer.fee);
            }
        }
        else{
            require(msg.value >= offer.price, "Market: insufficient value has been sent");
            if(priceAfterFee-royaltyAmount>0){
                payable(offer.seller).transfer(priceAfterFee-royaltyAmount);
            }
            if(royaltyAmount > 0){
                payable(royaltyReceiver).transfer(royaltyAmount);
                emit RoyaltyPayment(msg.sender, royaltyReceiver, offer.paymentTokenAddress, royaltyAmount, offer.nftAddress,
                offer.nftTokenId);
            }
        }
        emit BuyMarketMintingOffer(_offerId, offer.nftAddress, offer.nftTokenId, offer.amount, offer.paymentTokenAddress, offer.price,
        offer.seller, offer.buyer, offer.royaltyReceiver);
    }

    function cancelOffer(uint256 _offerId) public onlyOwner{
        require(offers[_offerId].seller != address(0), "Market: offer is not valid");
        Offer memory offer = offers[_offerId];
        delete offers[_offerId];
        emit CancelMarketMintingOffer(_offerId, offer.nftAddress, offer.nftTokenId, offer.amount, offer.seller, offer.buyer);
    }

    function getOffer(uint256 _offerId) public view returns(Offer memory){
        return offers[_offerId];
    }

    function setOfferValidity(uint blockCountValidity) public onlyOwner{
        _offerValidityBlocks = blockCountValidity;
    }

    receive() external payable {

    }

    fallback() external payable {

    }

    function withdraw(address contractAddress, uint16 standard, uint256 tokenId, uint256 amount) public onlyOwner{
        if(contractAddress==address(0)){
            payable(msg.sender).transfer(amount);
        }
        else if(standard==20){
            if(amount==0) amount = IERC20(contractAddress).balanceOf(address(this));
            IERC20(contractAddress).transfer(msg.sender, amount);
        }
        else if(standard==721){
            IERC721(contractAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        }
        else if(standard==1155){
            if(amount==0) amount = IERC1155(contractAddress).balanceOf(address(this), tokenId);
            IERC1155(contractAddress).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        }
    }

    function getRoyaltyInfo(address contractAddress, uint256 tokenId, uint256 price) internal view returns(address, uint256){
        (bool isSuccess, bytes memory response) = contractAddress.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)",IERC2981_ID));
        if(isSuccess && abi.decode(response, (bool))){
            return IERC2981(contractAddress).royaltyInfo(tokenId, price);
        }
        return (address(0), 0);
    }
}
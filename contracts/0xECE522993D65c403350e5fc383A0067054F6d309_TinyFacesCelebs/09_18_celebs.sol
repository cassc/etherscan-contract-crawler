// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'erc721a/contracts/ERC721A.sol';
import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol"; 
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol"; 
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/OperatorFiltererUpgradeable.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

error LotteryNotActive();
error ExceededLimit();
error WrongEther();
error ZeroQuantity();
error InvalidMerkle();
error NoWinner();
error NoParticipants();

contract TinyFacesCelebs is ERC721AUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, OperatorFiltererUpgradeable {
 
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;
    using MerkleProof for bytes32[];

    address proxyRegistryAddress;

    address payable[] private participants;
    uint[] private participantsAmounts;
    address public originalAddress;
    bytes32 private merkleRoot;
    uint256 public ticketRate;
    string public baseExtension;
    string public baseURI;
    bool public lotteryActive;

    function initialize() initializerERC721A initializer public {
         __ERC721A_init('TinyFaces Celebrities', 'TINY-CELEBS');
        __Ownable_init();
        __ReentrancyGuard_init();
        OperatorFiltererUpgradeable.__OperatorFilterer_init(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), true);
        ticketRate = 0.00 ether;
        baseExtension = '.json';
        baseURI = '';
        lotteryActive = false;
        originalAddress = address(0);
    }

    function pickWinner(string memory _newBaseURI) external onlyOwner {
        if (!lotteryActive) revert LotteryNotActive();

        address winner = randomAddress();

        if(winner == address(0)) revert NoWinner();

        baseURI = _newBaseURI;
        lotteryActive = false;
        delete participants;
        delete participantsAmounts;
        _mint(winner, 1);
    }

    function randomAddress() public view onlyOwner returns (address){

        if(participants.length == 0) revert NoParticipants();

        address winner = address(0);
        uint index = random() % totalTickets();
        uint currentAmount = 0;

        for(uint256 i = 0; i < participantsAmounts.length; i++) {
            currentAmount = currentAmount + participantsAmounts[i];
            if(currentAmount >= index){
                winner = participants[i];
                break;
            }
        }

        return winner;
    }

    function buyTicket(uint256 quantity, bytes32[] calldata proof) external payable nonReentrant {
        if (!lotteryActive) revert LotteryNotActive();

        if (!isWhiteListed(msg.sender, proof)) revert InvalidMerkle();

        if(quantity == 0) revert ZeroQuantity();

        if (ticketRate * quantity != msg.value) {
            revert WrongEther();
        }
       
        address payable sender = payable(msg.sender);

        uint256 left = ticketsLeft(msg.sender);
        if(quantity > left) revert ExceededLimit();
        
        participants.push(sender);  
        participantsAmounts.push(quantity);  
        
    }

    function ticketsLeft(address _account) public view returns (uint256) {

        ERC721A originalTinyFaces = ERC721A(originalAddress);
        uint256 balance = originalTinyFaces.balanceOf(_account);

        address payable sender = payable(_account);
        uint256 numTickets = ownedTickets(sender);

        return balance-numTickets;

    }

    function ownedTickets(address _account) public view returns (uint256) {
        uint256 numTickets = 0;

        address payable sender = payable(_account);

        for(uint256 i = 0; i < participants.length; i++) {
            if(participants[i] == sender){
                numTickets = numTickets + participantsAmounts[i];
            }
        }

        return numTickets;

    }

    function totalTickets() public view returns (uint256) {
        uint256 numTickets = 0;

        for(uint256 i = 0; i < participants.length; i++) {
            numTickets = numTickets + participantsAmounts[i];
        }

        return numTickets;
    }

    function isWhiteListed(address _account, bytes32[] calldata _proof) public view returns (bool) {
        return _verify(leaf(_account), _proof);
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : '';
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function toggleLottery() public onlyOwner {
        lotteryActive = !lotteryActive;
    }

    function renounceOwnership() public override onlyOwner {}

    function setTicketRate(uint256 _ticketRate) public onlyOwner {
        ticketRate = _ticketRate;
    }

    function setOriginalAddress(address _address) public onlyOwner {
        originalAddress = _address;
    }

    function random() onlyOwner private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length)));
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}
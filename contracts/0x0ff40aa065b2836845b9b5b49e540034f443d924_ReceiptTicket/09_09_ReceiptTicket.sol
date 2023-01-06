// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "ERC721A/ERC721A.sol";
import {MerkleProof} from "openzeppelin/utils/cryptography/MerkleProof.sol";
import {Base64} from "openzeppelin/utils/Base64.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/utils/Strings.sol";

contract ReceiptTicket is ERC721A, Ownable {
    // mint variables
    uint256 public TICKET_PRICE = 0.00777 ether;
    uint256 public WORM_FAN_TICKET_PRICE = 0.00333 ether;
    uint256 public MAX_WORM_FAN_MINTS = 5;
    bytes32 public merkleRoot;
    string public imageURI;
    string private _description =
        "Welcome to the United States of America. Please show this receipt at the exit. Thank you. At the end of the 48 hour minting window, 14 winners will be randomly selected to receive a 1/1 NFT.";
    bool public canMint;
    uint256 public mintCloseTime;
    mapping(address => uint256) public wormFanMints;

    error MintClosed();
    error NotAWormFan();
    error IncorrectPrice();
    error WormFanMaxReached();
    error TooEarly();

    // drawing variables
    address public ticketContract;
    uint256 public lastDrawBlock;
    uint256 public currentWinnerIndex;

    error AllWinnersDrawn();
    error AlreadyPickedThisBlock();
    error TicketBurned();

    constructor(string memory _imageURI, address _ticketContract, bytes32 _merkleRoot)
        ERC721A("Receipt Ticket", "RCPT_TKT")
    {
        ticketContract = _ticketContract;
        imageURI = _imageURI;
        merkleRoot = _merkleRoot;
    }

    // Internal utility functions

    function _mintOpen() internal view returns (bool) {
        return canMint && block.timestamp < mintCloseTime;
    }

    function _isAllowlisted(address _wallet, bytes32[] calldata _proof) internal view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(_wallet)));
    }

    // Mint functions
    function mint(uint256 quantity) external payable {
        if (!_mintOpen()) revert MintClosed();
        if (msg.value != TICKET_PRICE * quantity) revert IncorrectPrice();

        _mint(msg.sender, quantity);
    }

    function mintWormFan(uint256 quantity, bytes32[] calldata proof) external payable {
        if (!_mintOpen()) revert MintClosed();
        if (msg.value != WORM_FAN_TICKET_PRICE * quantity) revert IncorrectPrice();
        if (!_isAllowlisted(msg.sender, proof)) revert NotAWormFan();

        uint256 newMintCount = wormFanMints[msg.sender] + quantity;
        if (newMintCount > MAX_WORM_FAN_MINTS) revert WormFanMaxReached();
        wormFanMints[msg.sender] = newMintCount;

        _mint(msg.sender, quantity);
    }

    function pickWinner() external {
        if (block.timestamp < mintCloseTime) revert TooEarly();
        if (lastDrawBlock == block.number) revert AlreadyPickedThisBlock();
        if (currentWinnerIndex == 14) revert AllWinnersDrawn();

        uint256 winningToken = _getRandomToken();
        // ownerOf will revert if the ticket has been burned (already chosen)
        address winner = ownerOf(winningToken);

        // update all state before sending off token
        lastDrawBlock = block.number;
        currentWinnerIndex++;
        _burn(winningToken);

        IERC721A(ticketContract).transferFrom(owner(), winner, currentWinnerIndex);
    }

    function _getRandomToken() internal view returns (uint256) {
        // block.difficulty post eth merge is PREVRANDAO.
        // you can read more about that here: https://eth2book.info/altair/part2/building_blocks/randomness/#the-randao
        // but it's a reliably random number that is available on every block. since it's from the past,
        // we also mix in the basefee (decided when this current block is produced) to make it more unpredictable.

        return uint256(keccak256(abi.encodePacked(block.basefee, block.difficulty))) % totalSupply();
    }

    // Admin functions
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMintInfo(bool _canMint, uint256 _mintCloseTime) external onlyOwner {
        canMint = _canMint;
        mintCloseTime = _mintCloseTime;
    }

    function setPrices(uint256 _ticketPrice, uint256 _wormFanTicketPrice) external onlyOwner {
        TICKET_PRICE = _ticketPrice;
        WORM_FAN_TICKET_PRICE = _wormFanTicketPrice;
    }

    function setWormFanMaxMints(uint256 _maxMints) external onlyOwner {
        MAX_WORM_FAN_MINTS = _maxMints;
    }

    function setImageURI(string memory _imageURI) external onlyOwner {
        imageURI = _imageURI;
    }

    function setTicketContract(address _ticketContract) external onlyOwner {
        ticketContract = _ticketContract;
    }

    function setDescription(string memory _newDescription) external onlyOwner {
        _description = _newDescription;
    }

    function airdrop(address[] calldata _recipients) external onlyOwner {
        for (uint256 i = 0; i < _recipients.length; i++) {
            _mint(_recipients[i], 1);
        }
    }

    function withdraw() external onlyOwner {
        payable(this.owner()).transfer(address(this).balance);
    }

    // View functions
    function tokenURI(uint256 tokenID) public view override (ERC721A) returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        "{",
                        '"name": "Receipt Ticket #',
                        Strings.toString(tokenID),
                        '",',
                        '"description": "',
                        _description,
                        '",',
                        '"image": "',
                        imageURI,
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
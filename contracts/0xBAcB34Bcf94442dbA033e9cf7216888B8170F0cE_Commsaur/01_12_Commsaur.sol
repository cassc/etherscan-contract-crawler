// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//   .--.      .--.    ___ .-. .-.    ___ .-. .-.       .--.      .---.   ___  ___   ___ .-.
//  /    \    /    \  (   )   '   \  (   )   '   \    /  _  \    / .-, \ (   )(   ) (   )   \
// |  .-. ;  |  .-. ;  |  .-.  .-. ;  |  .-.  .-. ;  . .' `. ;  (__) ; |  | |  | |   | ' .-. ;
// |  |(___) | |  | |  | |  | |  | |  | |  | |  | |  | '   | |    .'`  |  | |  | |   |  / (___)
// |  |      | |  | |  | |  | |  | |  | |  | |  | |  _\_`.(___)  / .'| |  | |  | |   | |
// |  | ___  | |  | |  | |  | |  | |  | |  | |  | | (   ). '.   | /  | |  | |  | |   | |
// |  '(   ) | '  | |  | |  | |  | |  | |  | |  | |  | |  `\ |  ; |  ; |  | |  ; '   | |
// '  `-' |  '  `-' /  | |  | |  | |  | |  | |  | |  ; '._,' '  ' `-'  |  ' `-'  /   | |
//  `.__,'    `.__.'  (___)(___)(___)(___)(___)(___)  '.___.'   `.__.'_.   '.__.'   (___)
contract Commsaur is ERC721A, Ownable {
    uint256 public MINT_PRICE = 0.033 ether;
    uint16 public constant MAX_SUPPLY = 3333;

    address public withdrawalAddress =
        0x224f096cDFdb2Cd3f4796dE5F6019412B92E32dE; // gnosis safe

    string private baseURI;

    enum MintStatus {
        CLOSED,
        RESERVED,
        ALLOW_LIST,
        PUBLIC
    }
    bool public mintReserved = false;
    MintStatus public mintStatus;
    mapping(address => bool) allowList;

    constructor() ERC721A("Commsaur", "COMMSAUR") {}

    // @notice Will mint x amount of Commsaurs only if the mint status allows it
    // @dev since we're using erc721a, the safe mint takes a quantity amount
    function mintCommsaurs(uint256 commsaursToMint) external payable {
        require(tx.origin == msg.sender, "CS: Caller must be a real user");
        require(
            mintStatus == MintStatus.PUBLIC,
            "CS: Minting is currently closed!"
        );
        require(
            totalSupply() + commsaursToMint < MAX_SUPPLY,
            "CS: Minting would exceed max supply"
        );
        require(commsaursToMint > 0, "CS: Must mint at least one Commsaur");
        require(
            commsaursToMint <= 5,
            "CS: You can only mint a max of 5 Commsaurs per tx"
        );
        require(
            msg.value == MINT_PRICE * commsaursToMint,
            "CS: Ether value sent is not correct"
        );

        _safeMint(msg.sender, commsaursToMint);
        refundEthOverflow(commsaursToMint * MINT_PRICE);
    }

    // @notice Allows minting during allow list
    function mintAllowList() external payable {
        require(tx.origin == msg.sender, "CS: Caller must be a real user");
        require(
            mintStatus == MintStatus.ALLOW_LIST,
            "CS: Allow-list claiming is closed"
        );
        require(
            allowList[msg.sender],
            "CS: Address not elegible for Commsaur allow-list"
        );

        allowList[msg.sender] = false;
        _safeMint(msg.sender, 1);
        refundEthOverflow(MINT_PRICE);
    }

    function setMintStatus(uint256 status) external onlyOwner {
        require(
            status <= uint256(MintStatus.PUBLIC),
            "CS: Unknown mint status"
        );
        mintStatus = MintStatus(status);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setWithdrawalAddress(address _addr) external onlyOwner {
        withdrawalAddress = _addr;
    }

    function setAllowList(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = true;
        }
    }

    function reserveTokens() external onlyOwner {
        require(
            mintStatus == MintStatus.RESERVED,
            "CS: Reserved minting was closed"
        );
        require(!mintReserved, "CS: Reserved minting has already happened");

        _safeMint(msg.sender, 150);
        mintReserved = true;
    }

    // @notice in case contract mint calls send too much eth, we'll refund the difference
    function refundEthOverflow(uint256 amount) private {
        require(msg.value >= amount, "CS: Not enough ETH sent.");
        if (msg.value > amount) {
            payable(msg.sender).transfer(msg.value - amount);
        }
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(withdrawalAddress), address(this).balance);
    }

    // @notice ERC721A allows us to see more detailed information about a mint, this will be useful further down the line :eyes:
    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}
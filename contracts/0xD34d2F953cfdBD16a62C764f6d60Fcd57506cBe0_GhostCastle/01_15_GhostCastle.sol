// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract GhostCastle is ERC1155, AccessControl {
    bytes32 public constant MAINTAIN_ROLE = keccak256("MAINTAIN_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    Counters.Counter private _mintedCounter;
    mapping(uint256 => bool) public mintedToken;

    uint256 public constant TOTAL_SUPPLY = 5555;

    IERC721 private _weirdoGhostGang;

    address[] public payees = [0x870e2EdC0f87730c49Ae21B6f43aeE4a636b7C72, 0x0921d663401D11CE92A8B3b7B559B52bB05291C3];
    address private constant SIGNER = 0x0Ac584A240fbae9e6403c569A7cE29fC5C4d8912;

    event Withdraw(uint256);

    constructor(address weirdoGhostGangAddress) ERC1155("https://nft.may.social/nft-metadata/1/{id}") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MAINTAIN_ROLE, msg.sender);
        _grantRole(WITHDRAW_ROLE, msg.sender);
        _weirdoGhostGang = IERC721(weirdoGhostGangAddress);
        _mint(msg.sender, 0, 1, "0");
    }

    function setURI(string memory newuri) public onlyRole(MAINTAIN_ROLE) {
        _setURI(newuri);
    }

    function mint(uint256 wggTokenId, bytes memory sign) external {
        require(Address.isContract(msg.sender) == false, "mint: Prohibit contract calls");
        require(!mintedToken[wggTokenId], "mint: This token has minted");
        require(_mintedCounter.current() + 1 <= TOTAL_SUPPLY, "mint: Mint would exceed max supply");
        require(_weirdoGhostGang.ownerOf(wggTokenId) == msg.sender, "mint: This token is not yours");

        bytes32 digest = keccak256(abi.encodePacked(wggTokenId));
        require(digest.recover(sign) == SIGNER, "mint: Invalid signer");

        _mintedCounter.increment();
        uint256 tokenId = 1 + random() % 3;
        _mint(msg.sender, tokenId, 1, "0");
        mintedToken[wggTokenId] = true;
    }

    function random() private view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp
                    + block.difficulty
                    + uint256(keccak256(abi.encodePacked(block.coinbase))) / block.timestamp
                    + block.gaslimit
                    + uint256(keccak256(abi.encodePacked(msg.sender))) / block.timestamp
                    + block.number
                )
            )
        );
    }

    function hasMinted(uint256[] calldata tokenIds) external view returns (bool[] memory){
        bool[] memory ret = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ret[i] = mintedToken[tokenIds[i]];
        }
        return ret;
    }

    function mintedCount() external view returns (uint256){
        return _mintedCounter.current();
    }

    function withdraw() external onlyRole(WITHDRAW_ROLE) {
        uint256 balance = address(this).balance / 2;
        for (uint256 i = 0; i < payees.length; i++) {
            (bool sent,) = payees[i].call{value : balance}("");
            require(sent, "withdraw: Failed to send Ether");
        }

        emit Withdraw(balance);
    }

    function name() public pure returns (string memory) {
        return "Haunted House";
    }

    function symbol() public pure returns (string memory) {
        return "HH";
    }

    function totalSupply() external pure returns (uint256){
        return TOTAL_SUPPLY;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
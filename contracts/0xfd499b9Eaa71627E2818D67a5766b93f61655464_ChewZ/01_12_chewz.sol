/**
 * @dev https://twitter.com/chewzclub
 * ChewZ Club ⚈₋₍⚈
 * ****This is redeploy contract.****
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "./vrf.sol";

contract ChewZ is ERC721A, Ownable, VRFv2DirectFundingConsumer {
    constructor() ERC721A("ChewZ", "CHEWZ") {
        config = Config(5555, 5, 9000000000000000, 0, false, true, false);
    }

    Config public config;
    string revealUrl;
    string unrevealUrl;

    struct Config {
        uint256 maxSupply;
        uint256 maxMint;
        uint256 price;
        uint256 phase;
        bool reveal;
        bool defending;
        bool burnable;
    }

    address public defender = 0x4D93B024dBeFdd32bA64860eEc382d3d98df8cDe;
    mapping(address => bool) free_used;
    mapping(bytes32 => bool) hashed;

    // DEFEND MINT FUNCTION
    function CHEW_CHEW(
        uint256 count,
        bytes32 _hashedMessage,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable {
        require(config.phase == 1, "Invalid phase.");

        address signer = verify(_hashedMessage, _v, _r, _s);

        require(signer == defender, "verify failed");
        require(signer != address(0), "verify failed");
        require(!hashed[_hashedMessage], "hashed used.");

        _mint(count);

        free_used[msg.sender] = true;
        hashed[_hashedMessage] = true;
    }

    // NORMAL MINT
    function CHEW(uint256 count) external payable {
        require(config.phase == 2, "Invalid phase.");

        _mint(count);

        free_used[msg.sender] = true;
    }

    function _mint(uint256 count) private {
        uint256 pay = count * config.price;

        if (!free_used[msg.sender]) {
            pay -= config.price;
        }

        require(pay <= msg.value, "No enough Ether.");
        require(totalSupply() + count <= config.maxSupply, "Exceed maxmiumn.");
        require(_numberMinted(msg.sender) + count <= config.maxMint, "Cant mint more.");

        _safeMint(msg.sender, count);
    }

    function verify(
        bytes32 _hashedMessage,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) private pure returns (address) {
        address signer = ecrecover(_hashedMessage, _v, _r, _s);

        return signer;
    }

    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "not burn.");
        require(config.burnable, "cant burn");
        _burn(tokenId);
    }

    function tokenURI(uint256 _id)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(_id > 0 && _id <= totalSupply(), "Invalid token ID.");

        return
            config.reveal
                ? string(abi.encodePacked(revealUrl, revealId(_id)))
                : unreveal();
    }

    function unreveal() private view returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"description": "","image":"', unrevealUrl ,'"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function revealId(uint256 _id) private view returns (string memory) {
        uint256 maxSupply = config.maxSupply;
        uint256[] memory temp = new uint256[](maxSupply + 1);

        for (uint256 i = 1; i <= maxSupply; i += 1) {
            temp[i] = i;
        }

        for (uint256 i = 1; i <= maxSupply; i += 1) {
            uint256 j = (uint256(keccak256(abi.encode(hash[0], i))) %
                (maxSupply)) + 1;

            (temp[i], temp[j]) = (temp[j], temp[i]);
        }

        return Strings.toString(temp[_id]);
    }

    function devMint(uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= config.maxSupply, "");
        _safeMint(msg.sender, _quantity);
    }

    function numberMinted(address _addr) public view returns (uint256) {
        return _numberMinted(_addr);
    }

    function tokensOfOwner(address owner)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function reveal(string calldata _revealUrl) external onlyOwner {
        config.reveal = true;
        revealUrl = _revealUrl;
    }

    function setUnrevealUrl(string calldata _url) external onlyOwner {
        unrevealUrl = _url;
    }

    function setMaxSupply(uint256 max) external onlyOwner {
        require(!config.reveal, "unable to call");
        require(max <= config.maxSupply, "invalid.");
        config.maxSupply = max;
    }

    function getHash() external onlyOwner {
        require(!hashRequested, "Already request.");
        _requestRandomWords();
    }

    function setDefender(address _defender) external onlyOwner {
        defender = _defender;
    }

    function setPrice(uint256 _price) external onlyOwner {
        config.price = _price;
    }

    function setDefending(bool _status) external onlyOwner {
        config.defending = _status;
    }

    function setBurnable(bool _status) external onlyOwner {
        config.burnable = _status;
    }

    function setPhase(uint256 _phase) external onlyOwner {
        config.phase = _phase;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "");
    }

    function withdrawLink() external onlyOwner {
        _withdrawLink();
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }
}
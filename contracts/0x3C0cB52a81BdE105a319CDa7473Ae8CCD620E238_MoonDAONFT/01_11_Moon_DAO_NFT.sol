//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "erc721a/contracts/ERC721A.sol";
import "./access/OperatorAccessControl.sol";
import "./Base64.sol";

contract MoonDAONFT is ERC721A, OperatorAccessControl {
    bytes32 public merkleRoot;
    mapping(address => bool) internal claimList;

    uint256 private _count = 0;

    string private _nftName = "Ticket to Space NFT";

    string private _image =
        "ipfs://Qmba3umb3db7DqCA19iRSSbtzv9nYUmP8Cibo5QMkLpgpP";

    uint256 private _switch = 0;

    constructor() ERC721A(_nftName, _nftName) Ownable() {}

    function addMerkleRoot(bytes32 _merkleRoot) public isOperatorOrOwner {
        merkleRoot = _merkleRoot;
    }

    function isWhitelist(bytes32[] calldata merkleProof)
        public
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            );
    }

    function claimedCount() public view returns (uint256) {
        return _count;
    }

    function isClaimed(address _address) public view returns (bool) {
        return claimList[_address];
    }

    function setImage(string memory image) public isOperatorOrOwner {
        _image = image;
    }

    function setSwitch(uint256 switch_) public isOperatorOrOwner {
        _switch = switch_;
    }

    function claim(bytes32[] calldata merkleProof) public {
        require(_switch == 1, "error:10002 switch off");
        require(_count < 9060, "error:10003 NFT mint limit reached");

        address claimAddress = _msgSender();
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "error:10000 not in the whitelist"
        );
        require(!claimList[claimAddress], "error:10001 already claimed");
        _safeMint(claimAddress, 1);
        claimList[claimAddress] = true;
        _count = _count + 1;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        _nftName,
                        " #",
                        toString(tokenId),
                        '", "image": "',
                        _image,
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
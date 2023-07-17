//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

contract ERC721 is ERC721A, Ownable, ERC2981 {
    using Strings for uint256;

    //@notice flg of pause
    bool public paused;

    //@notice maxSupply
    uint256 public maxSupply;

    //@notice cost
    uint256 public cost;

    //@notice merkleRoot
    bytes32 public merkleRoot;

    //@notice
    address public payAddress;

    //@notice userMintedAmount
    mapping(address => uint256) userMintedAmount;

    //@notice baseURI
    string public baseURI;

    //@notice baseExtension
    string public baseExtension = "";

    constructor() ERC721A("Traveler's Canvas", "TC") {
        paused = true;
        maxSupply = 10000;
        cost = 0;
        payAddress = 0xfc125FA3Ed72660224d4aF066B2065cC56492923;
        merkleRoot = 0xd2acc2564c47a7010e64e0887c5369a6fe5bcad01dc2ece1a706e9f6bb2417b5;
        baseURI = "https://mint-tracan.vercel.app/api/metadata/";
        _setDefaultRoyalty(0xE592a5263A0B289F181804f90c8bb72b23861208, 1000);
        _mint(0xE592a5263A0B289F181804f90c8bb72b23861208, 7000);
    }

    //
    //MINT
    //

    function mint(
        uint256 _mintAmount,
        uint256 _maxMintAmount,
        bytes32[] calldata _merkleProof
    ) public payable {
        require(!paused, "The contract is paused");

        bytes32 _leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender, _maxMintAmount)))
        );
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, _leaf),
            "user is not allowlisted"
        );

        uint256 currentMintedAmount = userMintedAmount[msg.sender];
        require(
            _mintAmount + currentMintedAmount <= _maxMintAmount,
            "You have already received your max amount"
        );

        uint256 _totalSupply = totalSupply();
        require(
            (_totalSupply + _mintAmount) <= maxSupply,
            "Mints num exceeded limit"
        );

        require(msg.value >= cost, "Not Enough Value");

        // Update user's minted amount before the actual minting
        userMintedAmount[msg.sender] = currentMintedAmount + _mintAmount;

        // Transfer ether to contract
        payable(payAddress).transfer(cost);

        // Execute mint
        _mint(msg.sender, _mintAmount);
    }

    function ownerMint(address _receiver, uint256 _amount) public onlyOwner {
        _mint(_receiver, _amount);
    }

    //@notice tokenURI
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //
    //SET
    //
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(
        string memory _newBaseExtension
    ) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    //@notice set Pause
    function setPaused(bool _newPause) external onlyOwner {
        paused = _newPause;
    }

    //@notice set Royality
    function setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    ) public onlyOwner {
        setDefaultRoyalty(_receiver, _feeNumerator);
    }

    //@notice set maxMintedNum
    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        maxSupply = _newMaxSupply;
    }

    //@notice set cost
    function setCost(uint256 _newCost) external onlyOwner {
        cost = _newCost;
    }

    //@notice set merkleRoot
    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    //@notice set address
    function setPayAddress(address _newPayAddress) external onlyOwner {
        payAddress = _newPayAddress;
    }

    //
    //GET
    //
    function getUserMintedAmount(address _user) public view returns (uint256) {
        return userMintedAmount[_user];
    }

    function getWhitelist(
        address _user,
        uint256 _maxMintAmount,
        bytes32[] calldata _merkleProof
    ) external view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(_user, _maxMintAmount));
        return MerkleProof.verify(_merkleProof, merkleRoot, _leaf);
    }

    //
    //INTERFACE
    //
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
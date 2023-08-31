// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "contracts/utils/SigUtils.sol";
import "contracts/utils/Minter.sol";
import "contracts/utils/Gabby721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract GabbyMasterpiece is Gabby721, SigUtils, Minter {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    mapping(address => uint256) public minted;

    event Mint(address to, uint256 tokenId);
    event MintWithSignature(address indexed to, uint256 indexed tokenId, uint256 indexed galleryId);

    constructor(address banker_, string memory name_, string memory symbol_, string memory baseURI_) Gabby721(name_, symbol_, baseURI_) {
        setBanker(banker_);
        setSuperMinter(_msgSender());
    }

    function mint(address to_) public onlyMinter(1) returns (uint256) {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        _spendQuota(1);
        _mint(to_, tokenId);

        emit Mint(to_, tokenId);
        return tokenId;
    }

    function mintWithSignature(uint256 galleryId_, uint256 value_, bytes calldata signature_) external payable returns (uint256) {
        address sender = _msgSender();

        bytes32 hash = keccak256(abi.encodePacked(galleryId_, value_, sender));
        require(verifySignature(hash, signature_), "signature error");

        require(minted[sender] == 0, "minted");
        require(msg.value == value_, "value error");

        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        minted[sender] = tokenId;

        _mint(sender, tokenId);

        emit MintWithSignature(sender, tokenId, galleryId_);
        return tokenId;
    }

    function withdraw(address to_) external onlyOwner {
        payable(to_).transfer(balanceOf(address(this)));
    }
}
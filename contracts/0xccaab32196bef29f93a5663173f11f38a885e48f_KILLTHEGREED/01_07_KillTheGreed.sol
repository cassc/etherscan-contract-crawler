//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract KILLTHEGREED is ERC721A, Ownable {
    using Strings for uint256;
    bytes32 public whitelistRoot;

    enum SaleStatus {
        Whitelist,
        Public,
        Closed
    }

    uint256 public MAX_SUPPLY = 1100;
    SaleStatus public saleStatus = SaleStatus.Closed;
    mapping(address => uint8) private _whitelist;
    mapping(address => uint8) private _publicCount;

    constructor(bytes32 _whitelistRoot) ERC721A("KILLTHEGREED", "KTG") {
        whitelistRoot = _whitelistRoot;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setSaleStatus(SaleStatus _newStatus) external onlyOwner {
        saleStatus = _newStatus;
    }

    function claimLion(uint256[] calldata tokens) external virtual {
        _burn(tokens[0], true);
        _burn(tokens[1], true);
        _burn(tokens[2], true);
        _burn(tokens[3], true);
    }

    // whitelist mint
    function mintWhiteList(uint8 numberOfTokens, bytes32[] memory proof)
        public
        payable
    {
        require(saleStatus == SaleStatus.Whitelist, "Greed list is not active");
        require(
            MerkleProof.verify(
                proof,
                whitelistRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not on the greedlist"
        );
        uint256 ts = totalSupply();
        require(
            numberOfTokens + _whitelist[msg.sender] < 3,
            "Exceed max available to mint"
        );

        require(
            ts + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );

        _whitelist[msg.sender] += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function reserve(uint256 n) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + n <= MAX_SUPPLY, "not enough tokens");
        _safeMint(msg.sender, n);
    }

    // metadata URI
    string private _baseTokenURI =
        "ipfs://QmYvGn42HYxQ2XXqjsGHydeDHFKPhDRNk9aor3kgtk4EMm/";

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // mint
    function mint(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(
            saleStatus == SaleStatus.Public,
            "Public sale must be active to mint tokens"
        );
        require(
            ts + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        require(
            numberOfTokens + _publicCount[msg.sender] < 3,
            "Exceeded max available to purchase"
        );

        _publicCount[msg.sender] += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function withdrawMoney() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
// SPDX-License-Identifier: MIT

// /&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&.
// /&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&.
// /&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&.
// /&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&.
// /&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&.
// /&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%,............
// /&&&&&&&&&&&&#                                                    .&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                                                    .&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                                                    .&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                                                    .&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                                                    .&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                                                    .&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                &&&&&&&&&&&&&&&&&&&&*               .&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                &&&&&&&&&&&&&&&&&&&&*               .&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                &&&&&&&&&&&&&&&&&&&&*               .&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                &&&&&&&&&&&&&&&&&&&&*               .&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                &&&&&&&&&&&&&&&&&&&&*               .&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                ####################,               .&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                                                    .&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                                                    .&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                                                    .&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                                                    .&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                                                    .&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                                                    .&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// /&&&&&&&&&&&&#                &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
// .,,,,,,,,,,,,(################&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
//              /&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
//              /&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
//              /&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
//              /&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
//              /&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Photopia is Ownable, ERC721Enumerable {
    uint256 private constant MAX_PUBLIC_MINT = 1; // Max public mint 1
    bool public IS_SALE_ACTIVE = false;
    bool public IS_REVEALED = false;
    string private _tokenUri = "";
    string private _unrevealedUri = "";
    mapping(address => uint256) private balances;

    constructor() ERC721("Photopia", "P22") {}

    function tokensMinted(address address_) public view returns (uint256) {
        return balances[address_];
    }

    function mint() public {
        require(IS_SALE_ACTIVE, "Sale is not active yet");
        require(
            tokensMinted(msg.sender) < MAX_PUBLIC_MINT,
            "Can't claim more than one token"
        );
        balances[msg.sender]++;
        uint256 id = totalSupply();
        id++;
        _safeMint(msg.sender, id);
    }

    function airDropMany(address[] memory addr_) external onlyOwner {
        uint256 id = totalSupply();
        for (uint256 i = 0; i < addr_.length; i++) {
            id++;
            _safeMint(addr_[i], id);
        }
    }

    /*
      Owner Functions
    */
    function setSaleState(bool state_) external onlyOwner {
        IS_SALE_ACTIVE = state_;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setBaseUri(string calldata tokenUri_) external onlyOwner {
        _tokenUri = tokenUri_;
    }

    function setUnrevealedUri(string calldata unrevealedUri_)
        external
        onlyOwner
    {
        _unrevealedUri = unrevealedUri_;
    }

    function setRevealState(bool state_) external onlyOwner {
        IS_REVEALED = state_;
    }

    /*
      Overrides
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenUri;
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        if (!IS_REVEALED) {
            return _unrevealedUri;
        }

        return super.tokenURI(tokenId_);
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Can't renounce ownership");
    }
}
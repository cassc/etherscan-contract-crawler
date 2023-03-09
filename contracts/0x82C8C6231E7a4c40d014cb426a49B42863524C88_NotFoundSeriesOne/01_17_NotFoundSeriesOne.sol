//SPDX-License-Identifier: MIT
/* 
  _  _    ___  _  _     ____            _              ___             
 | || |  / _ \| || |   / ___|  ___ _ __(_) ___  ___   / _ \ _ __   ___ 
 | || |_| | | | || |_  \___ \ / _ \ '__| |/ _ \/ __| | | | | '_ \ / _ \
 |__   _| |_| |__   _|  ___) |  __/ |  | |  __/\__ \ | |_| | | | |  __/
    |_|  \___/   |_|   |____/ \___|_|  |_|\___||___/  \___/|_| |_|\___|
   */                                                                     
pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./opensea-operator-filterer/DefaultOperatorFilterer.sol";

//Built by --error

contract NotFoundSeriesOne is DefaultOperatorFilterer, Ownable, ERC721Enumerable {
    constructor() ERC721("Not Found - Series One", "404") {}

    uint256 public maxSupply = 404;
    uint256 minted;
    string public baseURI;
    string public baseExtension = ".json";
    mapping(address => uint256) userMint;
    bool public paused = false;

    function claim(uint256 _tokenID) public payable {
    require(msg.value >= 0.01 ether, "Insufficient payment");
    require(minted < maxSupply, "Max Supply is 404");
    require(_tokenID < maxSupply, "Token ID should be between 0-403");
    require(userMint[msg.sender] == 0, "Can only mint 1 NFT");
    require(!_exists(_tokenID), "Another user has minted this token ID");
    require(!paused, "The contract is paused.");

    userMint[msg.sender] += 1;
    minted++;
    _safeMint(msg.sender, _tokenID);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = string(abi.encodePacked(_newBaseURI));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _exists(tokenId);

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }
}
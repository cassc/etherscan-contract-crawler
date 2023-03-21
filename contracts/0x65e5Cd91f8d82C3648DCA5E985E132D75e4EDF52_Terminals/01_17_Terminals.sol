//SPDX-License-Identifier: MIT
/*
  ______                    _             __    
 /_  __/__  _________ ___  (_)___  ____ _/ /____
  / / / _ \/ ___/ __ `__ \/ / __ \/ __ `/ / ___/
 / / /  __/ /  / / / / / / / / / / /_/ / (__  ) 
/_/  \___/_/  /_/ /_/ /_/_/_/ /_/\__,_/_/____/  */
//Terminals v1                                                            
pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./opensea-operator-filterer/DefaultOperatorFilterer.sol";

contract Terminals is DefaultOperatorFilterer, Ownable, ERC721Enumerable {
    constructor() ERC721("Terminals", "CMD") {}

    uint256 public maxSupply = 999;
    uint256 minted;
    string public baseURI;
    string public baseExtension = ".json";
    bool public paused = false;
    bool public mergeEnabled = false;
    uint256 constant public mergeId = 1;
    mapping(uint256 => address) public tokenOwner;
    mapping(address => uint256) public tokenBalance;

    function mint(uint256 _tokenID) public payable {
    require(msg.value >= 0.005 ether, "Terminals are 0.005 ether");
    require(minted < maxSupply, "Max Supply is 999.");
    require(_tokenID < maxSupply, "Terminal ID must be between 0-998");
    require(!_exists(_tokenID), "Another user has claimed this terminal");
    require(!paused, "Terminals are not live");

     minted++;
    _safeMint(msg.sender, _tokenID);
    }

    function Merge(uint256 _tokenId, uint256[] memory consumedTokenIds) external {
        require(mergeEnabled, "Can't merge yet.");
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not approved.");

        uint256 count = consumedTokenIds.length;

        uint256 mergers;
        for (uint256 i; i < count;) {
            uint256 tokenId = consumedTokenIds[i];
            
            _burn(tokenId);
        }

        _safeMint(msg.sender, _tokenId);
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

    function setMerge(bool _state) public onlyOwner {
        mergeEnabled = _state;
    }
}
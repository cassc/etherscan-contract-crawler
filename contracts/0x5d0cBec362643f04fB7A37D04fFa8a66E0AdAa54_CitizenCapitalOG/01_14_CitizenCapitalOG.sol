// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CitizenCapitalOG is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string _baseTokenURI;

    bool public locked = false;
    address public ctzncAddress;

    uint256 private __limit = 700;

    constructor(string memory baseURI, address ctzncAddress) ERC721("Citizen Capital", "CITCAP")  {
        setBaseURI(baseURI);
        setCtzncAddress(ctzncAddress);
    }
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function setBaseURI(string memory baseURI) internal onlyOwner() {
        _baseTokenURI = baseURI;
    }
    function mint(uint _num) public payable {
        uint256 supply = totalSupply() + 1;
        require(supply + _num - 1 <= __limit, "Exceeds maximum NFT supply" );
        for(uint256 i; i < _num; i++){
            _safeMint(msg.sender, supply + i );
        }
        bool success = IERC20(ctzncAddress).transferFrom(msg.sender, address(this), _num*10**18);
        require(success, "Something went wrong");
    }
    function setLock(bool _newState) external onlyOwner() {
        locked = _newState;
    }
    function setCtzncAddress(address _newAddress) private {
        ctzncAddress = _newAddress;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(!locked, "Cannot transfer - transfer locked");
        super._beforeTokenTransfer(from, to, tokenId);
    }


}
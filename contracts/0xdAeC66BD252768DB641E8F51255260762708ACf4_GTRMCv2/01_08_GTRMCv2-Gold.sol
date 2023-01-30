// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
    function decimals() external view returns (uint8);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract GTRMCv2 is ERC721AQueryable, Ownable, Pausable {

    uint256 public _maxSupply;
    string public _baseUri;
    
    constructor() ERC721A("GTRMC Gold", "GTRMC") {
        _maxSupply = 275;
    }


    //
    // MIXED FUNCTIONS
    //

    //allow self burning or admin burning
    function burn(uint256 tokenId) external {
        require(tokenId < _totalMinted(), "INVALID_TOKEN");
        require(ownerOf(tokenId) == msg.sender || owner() == msg.sender, "NOT_PERMITTED");

        //burn and do not require built in approvalCheck
        _burn(tokenId, false);
    }

    //
    // INTERNAL FUNCTIONS
    //
    function _baseURI() internal view virtual override returns (string memory uri) { return _baseUri; }
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override {
        //stop transfers unless not paused, minting or person is owner
        require(paused() == false || from == address(0) || msg.sender == owner(), "NOT_PERMITTED");

        //call base function
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    //
    // ADMIN FUNCTIONS
    //

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }
    function setTokenBaseUri(string memory url) external onlyOwner { _baseUri = url; }

    function mintAirdrop(address[] calldata addresses) external onlyOwner {
        require(_totalMinted() + addresses.length <= _maxSupply, "MAX_SUPPLY_REACHED");

        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], 1);
        }
    }

    function withdrawToken(IERC20 token, uint256 amount, address to) external onlyOwner {
        if (address(token) == address(0)) {
            (bool success, ) = to.call{value: (amount == 0 ? address(this).balance : amount)}(new bytes(0)); 
            require(success, "NATIVE_TRANSFER_FAILED");
        } else {
            (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, (amount == 0 ? token.balanceOf(address(this)) : amount))); 
            require(success && (data.length == 0 || abi.decode(data, (bool))), "ERC20_TRANSFER_FAILED");
        }
    }

    receive() external payable {}
}
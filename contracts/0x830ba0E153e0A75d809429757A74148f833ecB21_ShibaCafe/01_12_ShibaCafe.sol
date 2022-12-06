// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract ShibaCafe is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant threshold = 4436;

    string private constant baseURI = "ipfs://bafybeif34dq27f4rz65kp5kpq42gedua6jbto3c3ijf5axu4d2dalzxjx4/";
    address public immutable beneficiary;
    uint256 public immutable cost;

    uint256 public nextTokenId = 0;

    event minted(uint256 id);

    error MaxNumberOfNftsBought();
    error IncorrectFunds();
    error MaxSupplyReached();

    constructor(
        address _beneficiary,
        uint256 _cost
    ) ERC721("SHIBACAFE", "SHIBACAFE") {
        beneficiary = _beneficiary;
        cost = _cost;
    }

    function mint(uint256 nbrShibas) external payable {
        if (nbrShibas > 20) revert MaxNumberOfNftsBought();
        if (msg.value != cost * nbrShibas) revert IncorrectFunds();
        if (nextTokenId + nbrShibas > threshold) revert MaxSupplyReached();

        for (uint256 i = 0; i < nbrShibas; i++) {
            _mint(msg.sender, nextTokenId);
            emit minted(nextTokenId);

        unchecked {
            ++nextTokenId;
        }
        }
    }

    function tokenURI(uint256 id)
    public
    pure
    virtual
    override
    returns (string memory)
    {
        return string(abi.encodePacked(baseURI, id.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721)
    returns (bool)
    {
        return
        interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    virtual
    returns (address, uint256)
    {
        return (beneficiary, (_salePrice * 5) / 100);
    }

    function withdrawFees() external {
        (bool succeeded, ) = beneficiary.call{value: address(this).balance}("");
        require(succeeded);
    }
}
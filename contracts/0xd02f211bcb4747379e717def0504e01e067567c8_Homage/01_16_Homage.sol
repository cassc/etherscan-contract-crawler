// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./HomageBase.sol";
import "./ERC2981/ERC2981ContractWideRoyalties.sol";

contract Homage is HomageBase, ERC1155, ERC2981ContractWideRoyalties, Ownable {
    address payable private _payeeA;
    address payable private _payeeB;

    // Minted is a bitmap organized like the following:
    // - The LSB defines if the contract is open for minting or not. Note: the
    // owner can always mint.
    // - From the second LSB on if a token has been minted, e.g. token with id 1
    // is represented by the second LSB that is 0x0000…0010.
    uint256 public minted;

    constructor() ERC1155("") {
        // Assign 5% royalties to msg.sender
        _setRoyalties(_msgSender(), 500);
        _payeeA = payable(_msgSender());
        _payeeB = payable(0x39596955f9111e12aF0B96A96160C5f7211B20EF);
    }

    function start() external onlyOwner {
        minted |= 1;
    }

    function stop() external onlyOwner {
        minted &= type(uint256).max - 1;
    }

    function setPayees(address payable payeeA, address payable payeeB)
        external
        onlyOwner
    {
        _payeeA = payeeA;
        _payeeB = payeeB;
    }

    function mint(
        address to,
        uint24 outer,
        uint24 inner
    ) external payable {
        uint256 tokenId = _colorsToTokenId(outer, inner);
        require(minted & (1 << tokenId) == 0, "Homage: token already minted");
        if (_msgSender() == owner()) {
            require(msg.value == 0, "Homage: wrong amount");
        } else {
            require(minted & 1 == 1, "Homage: minting stopped");
            require(msg.value == 0.2 ether, "Homage: wrong amount");
            (bool success, ) = _payeeA.call{value: 0.16 ether}("");
            require(success, "Homage: unable transfer to A");
            (success, ) = _payeeB.call{value: 0.04 ether}("");
            require(success, "Homage: unable transfer to B");
        }
        minted |= 1 << tokenId;
        _mint(to, tokenId, 1, "");
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(
            tokenId > 0 && minted & (1 << tokenId) > 1,
            "Homage: token doesn't exist"
        );
        return string(_tokenJSON(tokenId));
    }

    /// @notice Allows to set the royalties on the contract
    /// @dev This function in a real contract should be protected with a onlyOwner (or equivalent) modifier
    /// @param recipient the royalties recipient
    /// @param value royalties value (between 0 and 10000)
    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
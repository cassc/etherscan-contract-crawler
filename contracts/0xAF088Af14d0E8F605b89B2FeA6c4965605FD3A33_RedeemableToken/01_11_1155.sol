// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

abstract contract ForgeTokenContract {
    function mint(address to, uint256 amount) public virtual;
}

contract RedeemableToken is ERC1155, Ownable, ERC1155Burnable {
    string private _name = "BoxCatBall";
    string private _symbol = "BCB";

    constructor() ERC1155("BOXCAT") {}

    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public supplyLimit;
    mapping(uint256 => address) public forgingContractAddresses;
    mapping(uint256 => string) public tokenURIs;

    // Mint function
    function airdrop(
        address[] calldata tos,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        for (uint256 i = 0; i < tos.length; i++) {
            mint(tos[i], tokenId, amount);
        }
    }

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        require(
            tokenSupply[tokenId] + amount <= supplyLimit[tokenId],
            "Limit reached"
        );

        tokenSupply[tokenId] = tokenSupply[tokenId] + amount;

        _mint(to, tokenId, amount, "");
    }

    // Forge function
    function forgeToken(uint256 tokenId, uint256 amount) public {
        require(
            forgingContractAddresses[tokenId] !=
                0x0000000000000000000000000000000000000000,
            "No forging address set for this token"
        );
        require(
            balanceOf(msg.sender, tokenId) >= amount,
            "Doesn't own the token"
        ); // Check if the user own one of the ERC-1155

        burn(msg.sender, tokenId, amount); // Burn one the ERC-1155 token

        ForgeTokenContract forgingContract = ForgeTokenContract(
            forgingContractAddresses[tokenId]
        );
        forgingContract.mint(msg.sender, amount); // Mint the ERC-721 token
    }

    // --------
    // Getter
    // --------

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return tokenURIs[tokenId];
    }

    // --------
    // Setter
    // --------

    function setTokenURIs(uint256 tokenId, string calldata newUri)
        public
        onlyOwner
    {
        tokenURIs[tokenId] = newUri;
    }

    function setSupply(uint256 tokenId, uint256 newSupply) public onlyOwner {
        supplyLimit[tokenId] = newSupply;
    }

    function setForgingAddress(uint256 tokenId, address forgingAddress)
        public
        onlyOwner
    {
        forgingContractAddresses[tokenId] = forgingAddress;
    }

    // In case someone send money to the contract by mistake
    function withdrawFunds() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
}
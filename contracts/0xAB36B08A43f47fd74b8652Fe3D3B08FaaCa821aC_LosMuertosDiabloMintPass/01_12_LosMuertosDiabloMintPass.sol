// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// @author narghev dactyleth

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";

contract LosMuertosDiabloMintPass is ERC1155Pausable, Ownable {
    string private baseURI;
    uint256 public constant PASS_ID = 0;
    address private diablosMintingContract;

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI = _baseURI;
    }

    function airdrop(address[] calldata addrs, uint256[] calldata amounts)
        external
        onlyOwner
    {
        require(addrs.length == amounts.length, "Lengths mismatch");
        for (uint256 i = 0; i < addrs.length; i++) {
            _mint(addrs[i], PASS_ID, amounts[i], "");
        }
    }

    // Trading can be paused and all tokens can be burnt after Diablo mint
    function burn(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 amount = balanceOf(accounts[i], PASS_ID);
            _burn(accounts[i], PASS_ID, amount);
        }
    }

    function setDiablosMintingContract(address _diablosMintingContract)
        external
        onlyOwner
    {
        diablosMintingContract = _diablosMintingContract;
    }

    // We will set the base URI to a burnt image after the snapshot is taken
    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function burnOnMint(address burnTokenAddress, uint256 amount) external {
        // Burn request will come from the minting contract
        require(msg.sender == diablosMintingContract, "Invalid burner address");
        _burn(burnTokenAddress, PASS_ID, amount);
    }

    function uri(uint256 typeId) public view override returns (string memory) {
        require(typeId == PASS_ID, "Only typeId 0 is supported");
        return baseURI;
    }
}
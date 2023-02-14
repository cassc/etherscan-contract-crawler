// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//0x447871434ad0067844b5e641330d7F86Cd72CfD9 - Goerli
//0x666f6f0000000000000000000000000000000000000000000000000000000000 bytes32

contract PoxEthOg is ERC721, ERC721Enumerable, Ownable {

    mapping(uint256 => bool) minted;
    mapping(uint256 => bytes32) seedMapping;
    address genesisPassVault;
    IERC721 passContract;

    constructor(address _passContract, address vault) ERC721("PoxEth", "POX-OG")
    {
        passContract = IERC721(_passContract);
        genesisPassVault = vault;
    }

    function hasClaimed(uint256 passId) public view returns (bool)
    {
        return minted[passId];
    }

    function setPassContract(address _passContract) public onlyOwner
    {
        passContract = IERC721(_passContract);
    }

    function setVault(address _vault) public onlyOwner
    {
        genesisPassVault = _vault;
    }

    function mint(uint256 passId, bytes32 seed) public {
        require(passContract.ownerOf(passId) == msg.sender, "Cannot claim non-owner");
        require(minted[passId] == false, "Already Claimed");
        require(passContract.isApprovedForAll(msg.sender, address(this)), "Contract not approved");

        //Need to deposit the pass into the vault
        passContract.transferFrom(msg.sender, genesisPassVault, passId);

        _safeMint(msg.sender, passId);

        seedMapping[passId] = seed;
        minted[passId] = true;
    }

    function getSeed(uint256 tokenId) public view returns(bytes32) {
        return seedMapping[tokenId];
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://poxeth.xyz/json/";
    }

    function safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
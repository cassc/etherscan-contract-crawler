// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import './AbstractERC1155Factory.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/***
   ________                     _      __             __                __  __              
  / ____/ /_  _________  ____  (_)____/ /__  _____   / /   ____  ____  / /_/ /_  ____  _  __
 / /   / __ \/ ___/ __ \/ __ \/ / ___/ / _ \/ ___/  / /   / __ \/ __ \/ __/ __ \/ __ \| |/_/
/ /___/ / / / /  / /_/ / / / / / /__/ /  __(__  )  / /___/ /_/ / /_/ / /_/ /_/ / /_/ />  <  
\____/_/ /_/_/   \____/_/ /_/_/\___/_/\___/____/  /_____/\____/\____/\__/_.___/\____/_/|_|  


    ERC1155 mint token for Chronicles of the Inhabited Worlds NFT mint aka Chronicles Loot Box aka CLB
    @author shinji

    Legendary Token ID:     1001    Guaranteed Rare NFT
    Uncommon Token ID:      2001    Burner chooses Chronicles Department
    Common Token ID:        3xxx    Predetermined Chronicles Department

    TokenIDs
    --------
    1001: LEGENDARY
    2001: UNCOMMON
    3101: Space Army / Marine Corps
    3102: Space Army / Pilot Corps
    3103: Space Army / Medical Services Corps
    3104: Space Army / Engineering Corps
    3200: Space Navy
    3300: Communications Service
    3401: Intelligence Service / Special Operations Department
    3402: Intelligence Service / Federal Department of Investigation
    3403: Intelligence Service / Justice Department
    
*/

interface IChronicles {
     function mintFromBurn(address recipient, uint256 clbTokenId, bool isRare, uint16 department) external payable returns (uint256);
     function mintFromBurnBatch(address recipient, uint256[] memory clbTokenIds, bool[] memory isRares, uint16[] memory departments) external payable returns (uint256[] memory);
     function getNumReservedForClbs() external returns (uint256);
}

contract CoiwLootbox is AbstractERC1155Factory {

    address public ownerAddr = 0xdb275FaC4239aa53e3c56b7e999Dfc2B2406b671;
    IChronicles public chroniclesCollection;
    address public chroniclesAddr;

    // The date after which this CLB can no longer be burned to mint
    uint public burnToMintExpiration;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _burnToMintExpiration
    ) ERC1155(_uri) {
        name_ = _name;
        symbol_ = _symbol;
        burnToMintExpiration = _burnToMintExpiration;
    }

    /**
     * Init setup.
     */
    function setChroniclesContractAddr(address addr) external onlyOwner {
        chroniclesAddr = addr;
        chroniclesCollection = IChronicles(addr);
    }

    function setBurnToMintExpiration(uint256 expiry) external onlyOwner {
        burnToMintExpiration = expiry;
    }


    /**
     * For airdrop
     */
    function ownerMint(address wallet, uint256 tokenId, uint256 amount) external onlyOwner {
        _mint(wallet, tokenId, amount, "");
    }

    /**
     * For batch airdrop
     */
    function ownerMintBatch(address[] memory wallets, uint256[] memory tokenIds, uint256[] memory amounts) external onlyOwner {
        require(wallets.length == tokenIds.length, "wallets and tokenIds length mismatch");
        require(wallets.length == amounts.length, "wallets and amounts length mismatch");

        for (uint256 i = 0; i < wallets.length; i++) {
            _mint(wallets[i], tokenIds[i], amounts[i], "");
        }
    }

    /**
     * Called by CLB holder
     */
    function burnToMint(uint256 tokenId, uint16 desiredDepartment) external payable returns (uint256) {
        require(burnToMintExpiration >= block.timestamp, "This CLB has expired."); 
        require (IChronicles(chroniclesAddr).getNumReservedForClbs() >= 1);

        bool isGuaranteedRare;
        uint16 department;
        (isGuaranteedRare, department) = _getRareAndDept(tokenId, desiredDepartment);
        _burn(msg.sender, tokenId, 1);

        // Call the Chronicles contract's mintFromBurn function, and send eth (msg.value) there.
        // The minting price is checked in the Chronicles contract, not in this contract.
        return chroniclesCollection.mintFromBurn{value:msg.value}(msg.sender, tokenId, isGuaranteedRare, department);
    }

    /**
     * Called by CLB holder
     */
    function burnToMintBatch(uint256[] memory tokenIds, uint16[] memory desiredDepartments) external payable returns (uint256[] memory) {
        require(burnToMintExpiration >= block.timestamp, "This CLB has expired."); 
        require(tokenIds.length == desiredDepartments.length, "Length mismatch");
        require (IChronicles(chroniclesAddr).getNumReservedForClbs() >= tokenIds.length);

        bool[] memory isGuaranteedRares = new bool[](tokenIds.length);
        uint16[] memory departments = new uint16[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {

            bool isGuaranteedRare;
            uint16 department;
            (isGuaranteedRare, department) = _getRareAndDept(tokenIds[i], desiredDepartments[i]);

            isGuaranteedRares[i] = isGuaranteedRare;
            departments[i] = department;

            _burn(msg.sender, tokenIds[i], 1);
        }

        return chroniclesCollection.mintFromBurnBatch{value:msg.value}(msg.sender, tokenIds, isGuaranteedRares, departments);

    }


    function _getRareAndDept(uint256 tokenId, uint16 desiredDepartment) internal pure returns (bool,uint16) {
        require(tokenId == 1001 || tokenId == 2001 || desiredDepartment == 0, "Only Legendary and Uncommon CLBs can choose a Department");
        if (tokenId == 1001 || tokenId == 2001) {
            require(desiredDepartment != 0, "Please choose a desired Department");
        }

        bool isGuaranteedRare;
        uint16 department;
        if (tokenId == 1001) {
            isGuaranteedRare = true;
            department = desiredDepartment;
        }
        else if (tokenId == 2001) {
            isGuaranteedRare = false;
            department = desiredDepartment;
        }
        else {
            // For common CLBs, the department is exactly the CLB token id
            isGuaranteedRare = false;
            department = uint16(tokenId);
        }
        return (isGuaranteedRare, department);
    }


    /**
     * Safety function
     */
    function ownerBurn(
        address wallet,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        _burn(wallet, tokenId, amount);
    }


    function withdrawAll() external payable onlyOwner {
        uint256 all = address(this).balance;
        require(payable(ownerAddr).send(all));
    }

}
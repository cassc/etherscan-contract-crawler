// contracts/MSK001.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MaskDAO Golden Ticket - codename MSK001
 *
 * Authors: s.imo(at)etherealstudios.io
 * Created: 19.08.2021
 */
contract MSK001 is ERC721Enumerable, Ownable {

    // the maximum number of tokens
    uint256 public constant MAX_SUPPLY = 512;
    // the mint price in NCT
    uint256 public constant MINT_PRICE = 2000 * (10 ** 18);
    // metadata root uri
    string private _rootURI;
    // the HM pointer
    IERC721 private _hm;
    // the nct pointer
    IERC20 private _nct;
    // the DAO treasury
    address private _daoTreasury;
    // flag to activate the minting of tickets
    bool private _mintActivated;


    /**
     * @dev Constructor
     */
    constructor(address hmAddress, address nctAddress, address daoTreasury)
        ERC721("MaskDAO Golden Ticket", "MDGT")
    {
        _hm          = IERC721(hmAddress);
        _nct         = IERC20(nctAddress);
        _daoTreasury = daoTreasury;
        _mintActivated = false;
    }

    /**
    * @dev Mint and assign 'number' new tickets to an address
    */
    function assignTickets(address destination, uint256 number) public onlyOwner() {
        for(uint256 i = 0; i < number; i++) {
            uint mintIndex = totalSupply();
            if (mintIndex < MAX_SUPPLY) {
                _safeMint(destination, mintIndex);
            }
        }
    }

    /**
     * @dev Mint a new ticket
     */
    function mintTicket() public {
        require(_mintActivated,                  "Mint not enabled");
        require(totalSupply() < MAX_SUPPLY,      "Sale has already ended");
        require(balanceOf(_msgSender()) == 0,    "Caller already own a ticket");
        require(_hm.balanceOf(_msgSender()) > 0, "Caller does not own an HM");

        _nct.transferFrom(msg.sender, address(_daoTreasury), MINT_PRICE);

        uint mintIndex = totalSupply();
        if (mintIndex < MAX_SUPPLY) {
            _safeMint(msg.sender, mintIndex);
        }
    }

    /**
     * @dev Toggle the mint activation flag
     */
    function toggleMintState() public onlyOwner() {
        _mintActivated = !_mintActivated;
    }

    /**
     * @dev Returns true if the mint has been activated
     */
    function isMintEnabled() public view returns (bool) {
       return _mintActivated;
    }


    function setBaseURI(string memory uri) external onlyOwner() {
        _rootURI = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(bytes(_rootURI).length > 0, "Base URI not yet set");
        require(_exists(tokenId),           "Token ID not valid");

        return _baseURI();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _rootURI;
    }

}
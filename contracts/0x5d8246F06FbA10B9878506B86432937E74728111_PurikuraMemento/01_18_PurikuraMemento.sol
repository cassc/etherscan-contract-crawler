//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                   //
//                                                                                                                   //
//                                    _8888_                      ▄▀▀▀▀▀▌                                            //
//                            ,▀▀▀▀▀▀▀      ▀▀▀▀▀▀▀▀▌ █▀▀▀▀▀▀▀▀▀▀▀     █░                                            //
//                           █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄'░█               ▄█░                                             //
//                             ░░░░░░░░░░░░░░░░░░░░░█   ,████████████▀░                                              //
//                         █▀▀▀▀▀▄       ▄▀▀▀▀▀█   █   ,█░░░░░░░░░░░░░                                               //
//                          █     ▀▄▄▄▄▄▀    ▄█   █    ▀▄▄▄▄▄▄▄▄▄▄▄▄▄▄_                                              //
//                       ,▄▄▄█              █▄▄▄ █                  █░                                               //
//                      █                     █░█     █████     ,███░                                                //
//                     ²████████▀    ╓████████░█     █▀░░█     █▀▀░                                                  //
//                       ░░░░░░█    ,█░░░░░░░░█     █▀░ ▐     ██░                                                    //
//                     ,▄▄▄▄▄▄█     █▄▄▄▄▄▄▄▄▄_    █▀░ ▐     ██░   █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀╗           //
//                    ▐                     █▀    █▀░ ▐     ██░   █                                    ██░           //
//                   ²███████▀    ╓█████████░    █▀░ ▐     ██░   █     ,████████████████████████Γ     ██░            //
//                     ░░░░░▀    █░░░░░░░░░█    █▀░ ▐     ██░   █     Æ░░░░░░░░░░░░░░░░░░░░░░░░'     ██░             //
//                  ,▄▄▄▄▄▄█    █▄▄▄▄▄▄   █    █▀░ ▐     ██░   █                                    ██░              //
//                 Æ     ▄▄    ▄▄    █░  █    █▀░ ▐     ██░   █     ,████████████████████████Γ     ██░               //
//               Æ'    ,██¬    ▌░    █░ █    █▀░ ▐     ██░   █      Æ░░░░░░░░░░░░░░░░░░░░░░░'     ██░                //
//             ▄█     ▄██¬    ▌░░▌   └█     █▀░ ▐     ██░   █                                   ▄██░                 //
//            ▌     ▄█░█¬    █░░ ▌        ▄█▀░ ▐     ██░   █████████████████     ╓███████████████▀░                  //
//            ▌▄▄▄▄█░░███████░░   ████████▀░░ ▌███████░     ░░░░░░░░░░░░░░█     █░░░░░░░░░░░░░░░░░                   //
//              ░░░░░   ░░░░░░     ░░░░░░░░░     ░░░░░ ___,▀    j▀▀▀▀▀▀▀▀▀     ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█                   //
//                                                    █                                         █░                   //
//                                                   █_      ,▄██████████▀    ╓████████████████▀░                    //
//                                                     █    '░░░░░░░░░░░▄    ,█░░░░░░░░░░░░░░░░░                     //
//                                                    █     ▄▄▄▄▄▄▄▄▄▄▄█    '█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄_                     //
//                                                   █                                       █░                      //
//                                                   █████████████████▀     ╓███████████████▀░                       //
//                                                      ░░░░░░░░░░░░░▀     ,█▌░░░░░░░░░░░░░░░                        //
//                                                █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█     '█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄_                        //
//                                               █                                        █░                         //
//                                              ²████████████████████████████████████████▀░                          //
//                                                ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                           //
//       — Emi, Ayaka, Devin, Jack, Sally & Tommy                                                                    //
//                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PurikuraMemento is
    ERC721,
    IERC2981,
    Pausable,
    AccessControl,
    Ownable
{
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    uint256 public _maxSupply = 0;
    string public _baseURIextended = "https://galverse.art/api/purikura/";
    address payable private _withdrawalWallet = payable(0xE953B7Ee55579c0ad8DE383517Dbae1460cF0B59); // 0xSplit
    address payable private _royaltyWallet = payable(0xE953B7Ee55579c0ad8DE383517Dbae1460cF0B59); // 0xSplit
    uint256 public _royaltyBasis = 1000; // 10%
    // Sale
    bool public saleActive = false;
    uint256 public constant ETH_PRICE = 0.015 ether;
    uint256 public constant MAX_MINT_COUNT = 8888;

    struct SaleDetails {
        // Synthesized status variables for sale and presale
        bool publicSaleActive;
        bool presaleActive;
        // Price for public sale
        uint256 publicSalePrice;
        // Timed sale actions for public sale
        uint64 publicSaleStart;
        uint64 publicSaleEnd;
        // Timed sale actions for presale
        uint64 presaleStart;
        uint64 presaleEnd;
        // Merkle root (includes address, quantity, and price data for each entry)
        bytes32 presaleMerkleRoot;
        // Limit public sale to a specific number of mints per wallet
        uint256 maxSalePurchasePerAddress;
        // Information about the rest of the supply
        // Total that have been minted
        uint256 totalMinted;
        // The total supply available
        uint256 maxSupply;
    }

    constructor()
        ERC721("ShinseiGalversePurikuraMemento", "PURIKURA")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MANAGER_ROLE, msg.sender);

        grantRole(MANAGER_ROLE, 0x0C1d9B8A7aBD0C1e12D88DeDBd4e5b0ef72f3abc);
        grantRole(MANAGER_ROLE, 0x4492eCACB5da5D933af0e55eEDad4383BF8D2dB5);
        grantRole(MANAGER_ROLE, 0xEada52df08484e7b00d33d7403B0Cb5334fA103A);
        grantRole(MANAGER_ROLE, 0x7f8B18bBbf77fafDee934eaa359da3193eADa207);
        grantRole(MANAGER_ROLE, 0xb5b2C5dF2B7356380b9DBD6B5c4A1D562be99747);
    }

    function setWithdrawalWallet(address payable withdrawalWallet_)
        external
        onlyRole(MANAGER_ROLE)
    {
        _withdrawalWallet = (withdrawalWallet_);
    }
    function withdraw()
        external
        onlyRole(MANAGER_ROLE)
    {
        payable(_withdrawalWallet).transfer(address(this).balance);
    }

    function pause()
        public
        onlyRole(MANAGER_ROLE)
    {
        _pause();
    }
    function unpause()
        public
        onlyRole(MANAGER_ROLE)
    {
        _unpause();
    }

    function setBaseURI(string memory baseURI_)
        external
        onlyRole(MANAGER_ROLE)
    {
        _baseURIextended = baseURI_;
    }

    function contractURI()
        external
        view
        returns (string memory)
    {
        return string(abi.encodePacked(_baseURIextended, "metadata.json"));
    }

    function setMaxSupply(uint256 maxSupply_)
        external
        onlyRole(MANAGER_ROLE)
    {
        _maxSupply = maxSupply_;
    }

    function maxSupply()
        external
        view
        returns (uint256)
    {
        return _maxSupply;
    }

    function totalSupply()
        external
        view
        returns (uint256)
    {
        return _tokenIds.current();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(tokenId <= _tokenIds.current(), "Nonexistent token");
        return string(abi.encodePacked(_baseURIextended, tokenId.toString(), ".json"));
    }

    function setSaleActive(bool val)
        external
        onlyRole(MANAGER_ROLE) 
    {
        saleActive = val;
    }

    function transferOwnership(address _newOwner)
        public
        override
        onlyOwner
    {
        address currentOwner = owner();
        _transferOwnership(_newOwner);
        grantRole(MANAGER_ROLE, _newOwner);
        grantRole(DEFAULT_ADMIN_ROLE, _newOwner);
        revokeRole(MANAGER_ROLE, currentOwner);
        revokeRole(DEFAULT_ADMIN_ROLE, currentOwner);
    }

    function purchase(uint256 count)
        external
        payable
        whenNotPaused
        returns (uint256)
    {
        require(saleActive, "Sale has not begun");
        require((ETH_PRICE * count) == msg.value, "Incorrect ETH sent; check price!");
        require(count <= MAX_MINT_COUNT, "Tried to mint too many NFTs at once");
        require(_tokenIds.current() + count <= _maxSupply, "SOLD OUT");
        for (uint256 i=0; i<count; i++) {
            _tokenIds.increment();
            _mint(msg.sender, _tokenIds.current());
        }
        return _tokenIds.current();
    }

    // Allows an admin to mint for free, and send it to an address
    // This can be run while the contract is paused
    function teamMint(uint256 count, address recipient)
        external
        onlyRole(MANAGER_ROLE)
    returns (uint256)
    {
        require(_tokenIds.current() + count <= _maxSupply, "SOLD OUT");
        for (uint256 i=0; i<count; i++) {
            _tokenIds.increment();
            _mint(recipient, _tokenIds.current());
        }
        return _tokenIds.current();
    }

    function setRoyaltyWallet(address payable royaltyWallet_)
        external
        onlyRole(MANAGER_ROLE)
    {
        _royaltyWallet = (royaltyWallet_);
    }

    function saleDetails()
        external
        view
        returns (SaleDetails memory)
    {
        return SaleDetails(
            {
                publicSaleActive: saleActive,
                presaleActive: false,
                publicSalePrice: ETH_PRICE,
                publicSaleStart: 0,
                publicSaleEnd: type(uint64).max,
                presaleStart: 0,
                presaleEnd: 0,
                presaleMerkleRoot: bytes32(0),
                totalMinted: _tokenIds.current(),
                maxSupply: _maxSupply,
                maxSalePurchasePerAddress: MAX_MINT_COUNT
            }
        );
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        return (payable(_royaltyWallet), uint((salePrice * _royaltyBasis)/10000));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165, AccessControl)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    receive () external payable {}
    fallback () external payable {}
}
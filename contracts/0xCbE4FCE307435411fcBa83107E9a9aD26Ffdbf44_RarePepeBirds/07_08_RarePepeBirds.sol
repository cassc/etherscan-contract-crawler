// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./AccessControl.sol";
import "./ERC721A.sol";
import "./Types.sol";

contract RarePepeBirds is ERC721A {
    /*//////////////////////////////////////////////////////////////
                        CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint256 public constant MAXIMUM_SUPPLY = 10000;
    uint256 public constant PRESALE_FREE_CLAIM = 2;
    uint256 public constant PUBLIC_FREE_CLAIM = 1;

    /*//////////////////////////////////////////////////////////////
                        STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public freeSupplyRemaining = 6000;
    uint256 public maxPerAddress = 10;
    uint256 public price = 0.006 ether;
    mapping(address => bool) public allowlist;
    Types.SalePhase public salePhase;

    /*//////////////////////////////////////////////////////////////
                        MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier phaseCompliant() {
        require(
            salePhase == Types.SalePhase.PUBLIC ||
                (salePhase == Types.SalePhase.PRESALE &&
                    allowlist[msg.sender]) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "INVALID SALE PHASE"
        );
        _;
    }

    constructor(address[] memory admins)
        ERC721A("Rare Pepe Birds", "RPB", admins)
    {
        _safeMint(msg.sender, 1);
    }

    /*//////////////////////////////////////////////////////////////
                        MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function freeNestPepe() external phaseCompliant {
        require(_getAux(msg.sender) == 0, "ALREADY CLAIMED");

        uint256 quantity = salePhase == Types.SalePhase.PUBLIC
            ? PUBLIC_FREE_CLAIM
            : PRESALE_FREE_CLAIM;

        require(freeSupplyRemaining >= quantity, "FREE SUPPLY EXCEEDED");

        freeSupplyRemaining -= quantity;
        _setAux(msg.sender, uint64(quantity));
        _mintTo(msg.sender, quantity);
    }

    function nestPepe(uint256 quantity) external payable phaseCompliant {
        require(
            quantity + _numberMinted(msg.sender) - _getAux(msg.sender) <=
                maxPerAddress,
            "EXCEEDS MAX PER ADDRESS"
        );
        require(msg.value >= quantity * price, "INSUFFICIENT PAYMENT");
        _mintTo(msg.sender, quantity);
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function addAllowlist(address[] calldata addresses) external onlyAdmin {
        for (uint256 i; i < addresses.length; i++) {
            allowlist[addresses[i]] = true;
        }
    }

    function removeAllowlist(address[] calldata addresses) external onlyAdmin {
        for (uint256 i; i < addresses.length; i++) {
            delete allowlist[addresses[i]];
        }
    }

    function devMint(address to, uint256 quantity) external onlyAdmin {
        _mintTo(to, quantity);
    }

    function withdraw() public payable onlyAdmin {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "ETH TRANSFER FAILED");
    }

    function setPrice(uint256 newPrice) external onlyAdmin {
        price = newPrice;
    }

    function setMaxPerAddress(uint256 newMaxPerAddress) external onlyAdmin {
        maxPerAddress = newMaxPerAddress;
    }

    function setSalePhase(Types.SalePhase newSalePhase) external onlyAdmin {
        salePhase = newSalePhase;
    }

    function setBaseURI(string memory newBaseURI) external onlyAdmin {
        _setBaseURI(newBaseURI);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _mintTo(address to, uint256 quantity) internal {
        require(
            _totalMinted() + quantity <= MAXIMUM_SUPPLY,
            "MAX SUPPLY EXCEEDED"
        );
        _safeMint(to, quantity);
    }
}
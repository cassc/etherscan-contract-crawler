// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ERC721AUpgradeable.sol";
import "./ITomi.sol";


contract PioneerNFT is Initializable, ERC721AUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    
    address public saleContract;
    uint256 public epochInitalEnd;
    string public baseUri;
    ITomi public tomi;

    uint256 maxPurchaseInitial;

    event baseUriChanged(string _baseURI);

    modifier onlySale {
        require(_msgSender() == saleContract , "Not Authorized");
        _;
    }

     function initialize() initializerERC721A initializer public {
        __ERC721A_init("tomi Pioneers", "TPNR");
        __Ownable_init();
    }

    /**
     * @notice Initialize the funds wallet, auction house and base contracts,
     * populate the merkle root.
     * @dev This function can only be called once.
     */
    function setValues(address saleContract_, ITomi tomi_) public onlyOwner {
        saleContract = saleContract_;
        epochInitalEnd = block.timestamp.add(2 weeks);
        maxPurchaseInitial = 1500;
        tomi = tomi_;
    }

    receive() external payable {
        revert();
    }

    function saleMint(address buyer, uint amount) external onlySale{
        _mint(buyer, amount);
        tomi.mintThroughNft(buyer, amount);
    }


    function hasAuctionStarted() public view returns (bool) {
        if (
            totalSupply() > maxPurchaseInitial ||
            block.timestamp > epochInitalEnd
        ) {
            return true;
        }
        return false;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseUri = baseURI_;
        emit baseUriChanged(baseURI_);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default
     */
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

}
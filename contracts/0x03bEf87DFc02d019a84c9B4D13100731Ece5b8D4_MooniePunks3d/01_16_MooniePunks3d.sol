// SPDX-License-Identifier: MIT

/**
                                                     ^|cc)'
                                                     z****j
                                                     ^r**|`
                                                      ~**;
                                                      ~**;
                              .`^,;i~_-???_~i;,^`.    ~**;
                        .`;]jz*********************j[I)**;
                     `!t*********************************1`
                  `<n**************************************u+`
                ^/********************************************t"
              `t************************************************f^
            .}****************************************************).
           `v******************************************************c^
          ^z********************************************************z"
         `z**********************************************************z"
        .v************************************************************c'
        _**************************************************************[
        c**************************************************************z
        ****************************************************************.
        u**************************************************************c
        -**************************************************************}
        `**************************************************************^
         }************************************************************(
         .n**********************************************************v.
          `z********************************************************z^
           ^z******************************************************z,
            `c****************************************************z^
            I******************************************************~
           ^********************************************************,
          .v********************************************************c'
          }**********************************************************).
        :n************************************************************u;
      "r****************************************************************n,
    '(********************************************************************\`
  ']************************************************************************}'
.-z***************************************************************************[.
[******************************************************************************]
c******************************************************************************u
n******************************************************************************r
"z****************************************************************************z"
 '(**************************************************************************\`
   '"!+\****************************************************************t+i,'
       `****************************************************************^
        |**************************************************************t
        'z*************************************************************`
         I************************************************************<
          1**********************************************************\
          .x********************************************************u.
           `z******************************************************z^
            "z*****************************************************,
             ^v**************************************************c,
              ^**************************************************"
               c*************************************************
               t************************************************x
               (************************************************t
               )************************************************|
               |***********************ft***********************f
               t***********************``***********************n
               u***********************,"***********************z
               z***********************!!************************.
               {***********************,"***********************}

 */

pragma solidity ^0.8.9;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @notice This contract is a continutation of the Moonie Punk Promo contract.
 * It only allows users to claim a mint if they have blended their Moonie Punks
 * from within the master contract.
 * @dev Note For future reference, it might make more sense to simply expose the
 * burn function on the master contract and allow all the blending logic to be
 * handled by a future iteration of this contract.
 */

interface IClaimContract {
    function claimBlend(address _origin) external;

    function blended(address _user) external returns (uint256);
}

contract MooniePunks3d is ERC721AQueryable, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;
    string public uriPrefix = "";
    string public uriSuffix = ".json";

    uint256 public maxSupply = 650;

    address public masterContract;

    bool public zeroMinted = false;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _masterContract
    ) ERC721A(_tokenName, _tokenSymbol) {
        setMasterContract(_masterContract);
        _pause(); //Pause the contract on deployment
    }

    /**
     * @dev We want to confirm that users cannot claim until the zero mint
     * has been issued. This modifier will prevent that from happening.
     */
    modifier zeroHasBeenMinted() {
        require(zeroMinted, "Zero Mint has not been minted.");
        _;
    }

    function zeroMint(address _to) public onlyOwner {
        require(!zeroMinted, "Zero mint has been minted.");
        _safeMint(_to, 1);
        zeroMinted = true;
    }

    /**
     * @dev To avoid unneccessary gas expenditures, the claim function will
     * mint all available claims to the user at once.
     */
    function claimBlends() public whenNotPaused zeroHasBeenMinted nonReentrant {
        require(_totalMinted() < maxSupply, "Cannot exceed max supply");
        IClaimContract claimContract = IClaimContract(masterContract);
        uint256 blended = claimContract.blended(_msgSender());
        require(blended > 0, "No blends to claim");
        for (uint256 _i = 0; _i < blended; _i++) {
            claimContract.claimBlend(_msgSender());
        }
        _safeMint(_msgSender(), blended);
    }

    function setMasterContract(address _masterContract) public onlyOwner {
        masterContract = _masterContract;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    /**
     * @dev The owner will have the ability to lock the maxSupply.toHexString()
     * Note This is irreversible, so the community should be informed
     * if the decision is made to execute this function.
     */
    function lockSupply() public onlyOwner {
        require(_totalMinted() > 0, "Total minted must be greater than 0");
        maxSupply = _totalMinted();
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
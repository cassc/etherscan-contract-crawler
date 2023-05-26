// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./ERC721S.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

/*

OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
OOOO                                                                        OOOO
OOOO   OOOOO                                                        OOOOO   OOOO
OOOO  OOOO                                                            OOOO  OOOO
OOOO  OOOO                                                            OOOO  OOOO
OOOO  OOOOOOO                                                      OOOOOOO  OOOO
OOOO  OOOOOOOOOOOOOOOOOOOO                            OOOOOOOOOOOOOOOOOOOO  OOOO
OOOO  OOOOOOOOOOOOOOOOOOOOOOOOO                  OOOOOOOOOOOOOOOOOOOOOOOOO  OOOO
OOOO  OOOOOOOOOOOOOOOOOOOOOOOOOOO              OOOOOOOOOOOOOOOOOOOOOOOOOOO  OOOO
OOOO  OOOOOOOOOOOOOOOOOOOOOOOOOOOO            OOOOOOOOOOOOOOOOOOOOOOOOOOOO  OOOO
OOOO  OOOOOOOOOOOOOOOOOOOOOOOOOOOOO          OOOOOOOOOOOOOOOOOOOOOOOOOOOOO  OOOO
BBBB  BBBBBBBBBBB BBBBB   BBBBBBBBBB        BBBBBBBBBB   BBBBB BBBBBBBBBBB  BBBB
BBBB  BBBBBBBBBB         BBBBBBBBBBB        BBBBBBBBBBB        BBBBBBBBBBB  BBBB
BBBB  BBBBBBBBBBBBB BBBBBBBBBBBBBBBB        BBBBBBBBBBBBBBBB BBBBBBBBBBBBB  BBBB
BBBB  BBBBBBBBBB      BBBBBB   BBBBB        BBBBB   BBBBBB      BBBBBBBBBB  BBBB
BBBB      BBBBB      BBBBB    BBBBB          BBBBB    BBBBB      BBBBB      BBBB
BBBB              BBBBBB     BBBBB            BBBBB     BBBBBB              BBBB
BBBB                       BBBBBB              BBBBBB                       BBBB
BBBB                     BBBBBB                  BBBBBB                     BBBB
BBBB                    BBBBB                      BBBBB                    BBBB
BBBB                   BBBBB  BBBBBBB      BBBBBBB  BBBBB                   BBBB
BBBB                    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB                    BBBB
BBBB                      BBBBBBB     BBBB     BBBBBBB                      BBBB
EEEE                                                                        EEEE
EEEE                EEEE                               EEEEE                EEEE
EEEE               EEEEEE                              EEEEEE               EEEE
EEEE              EEEEEEE                              EEEEEEE              EEEE
EEEE            EEEEE            EEE        EEE            EEEEE            EEEE
EEEE            EE          EEEEEEEEEEEEEEEEEEEEEEEE          EE            EEEE
EEEE                   EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE                   EEEE
EEEE                  EEEEEEEE       EEEEEE       EEEEEEEE                  EEEE
EEEE  EE                EEEEEEEE                EEEEEEEE                EE  EEEE
EEEE  EE                    EEEEEEEEE      EEEEEEEE                     EE  EEEE
EEEE  EEE                         EEEEEEEEEEEE                         EEE  EEEE
EEEE  EEEE                           EEEEEE                           EEEE  EEEE
YYYY                                                                        YYYY
YYYY            YY                                            YY            YYYY
YYYY            YYYYY                                      YYYYY            YYYY
YYYY  YYY        YYYYYYYY                              YYYYYYYY        YYY  YYYY
YYYY  YYYYY       YYYYYYYY                            YYYYYYYY       YYYYY  YYYY
YYYY  YYYYYYYY   YYYYYYYYYY                          YYYYYYYYYY   YYYYYYYY  YYYY
YYYY  YYYYYYYYYYYYYYYYYYYYYYYYY                  YYYYYYYYYYYYYYYYYYYYYYYYY  YYYY
YYYY   YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY   YYYY
YYYY                                                                        YYYY
YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY

 */

contract DegenerateRegenerate is
    ERC721Sequential,
    ReentrancyGuard,
    Ownable,
    PaymentSplitter
{
    using Strings for uint256;
    using ECDSA for bytes32;
    mapping(bytes => uint256) private usedTickets;
    string public baseTokenURI;
    uint256 public startPresaleDate = 1639771200;
    uint256 public startMintDate = 1639850400;
    uint256 public constant MAX_SUPPLY = 7400;
    uint256 public constant MINT_PRICE = 0.1 ether;
    uint256 public constant MAX_PURCHASE_COUNT = 5;
    address private presaleSigner;
    address private staffSigner;
    address private obeySigner;

    constructor(
        uint256 _startPresaleDate,
        uint256 _startMintDate,
        string memory _baseTokenURI,
        address _presaleSigner,
        address _staffSigner,
        address _obeySigner,
        address[] memory _payees,
        uint256[] memory _shares
    )
        ERC721Sequential("DEGENERATE/REGENERATE", "OBEYDG")
        PaymentSplitter(_payees, _shares)
    {
        startPresaleDate = _startPresaleDate;
        startMintDate = _startMintDate;
        baseTokenURI = _baseTokenURI;
        presaleSigner = _presaleSigner;
        staffSigner = _staffSigner;
        obeySigner = _obeySigner;
    }

    function mint(uint256 numberOfTokens, bytes memory pass)
        public
        payable
        nonReentrant
    {
        if (
            startPresaleDate <= block.timestamp &&
            startMintDate > block.timestamp
        ) {
            uint256 mintablePresale = validateTicket(pass);
            require(
                numberOfTokens <= mintablePresale,
                "DR: Minting Too Many Presale"
            );
            useTicket(pass, numberOfTokens);
        } else {
            require(startMintDate <= block.timestamp, "DR: Sale Not Started");
            require(
                numberOfTokens <= MAX_PURCHASE_COUNT,
                "DR: Minting Too Many"
            );
        }

        require(totalMinted() + numberOfTokens <= MAX_SUPPLY, "DR: Sold Out");

        require(
            msg.value >= numberOfTokens * MINT_PRICE,
            "DR: Insufficient Payment"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function getHash() internal view returns (bytes32) {
        return keccak256(abi.encodePacked("OBEYDG", msg.sender));
    }

    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(signature);
    }

    function validateTicket(bytes memory pass) internal view returns (uint256) {
        bytes32 hash = getHash();
        address signer = recover(hash, pass);
        uint256 mintablePresale;
        if (signer == presaleSigner) {
            mintablePresale = 1;
        } else if (signer == staffSigner) {
            mintablePresale = 5;
        } else if (signer == obeySigner) {
            mintablePresale = 50;
        } else {
            revert("DR: Presale Invalid");
        }
        require(usedTickets[pass] < mintablePresale, "DR: Presale Used");
        return mintablePresale - usedTickets[pass];
    }

    function useTicket(bytes memory pass, uint256 quantity) internal {
        usedTickets[pass] += quantity;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setStartPresaleDate(uint256 _startPresaleDate) external onlyOwner {
        startPresaleDate = _startPresaleDate;
    }

    function setStartMintDate(uint256 _startMintDate) external onlyOwner {
        startMintDate = _startMintDate;
    }

    function withdraw(address payable account) public virtual {
        release(account);
    }

    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }
}
/* Development by 0x420.io */
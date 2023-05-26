// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// Afterparty Utopians -- 1,500 one-of-a-kind pieces each one part of the Afterparty founding community

// Truffle imports
//import "../openzeppelin-contracts/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
//import "../openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
//import "../openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";

// Remix imports
import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Last passed audits:
//   Mythrill:
//   MythX:
//   Optilistic :

contract AfterpartyUtopians721 is ERC721PresetMinterPauserAutoId {
    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeMath for uint;

    /***********************************|
    |        Structs                    |
    |__________________________________*/

    struct Pass {
        address minter;
        uint sale_price;
    }

    /***********************************|
    |        Variables and Constants    |
    |__________________________________*/
    uint16 public build = 5;
    uint256 public tokenCount = 0;
    mapping(uint256 => address) public tokenToAddress;
    address public mintpassContractAddress;

    Pass[] public passes;
    address payable public contract_owner;

    /***********************************|
    |        Events                     |
    |__________________________________*/

    event evtNftMintedFromPass(address _mpContract, uint256 _nftId, address _to);

    /***********************************|
    |        MAIN CONSTRUCTOR           |
    |__________________________________*/
    constructor() ERC721PresetMinterPauserAutoId("Afterparty Utopians", "APU", "https://nft.afterparty.ai/nft_metadata/1/") {
        contract_owner = payable(msg.sender);
        mintpassContractAddress = 0x0000000000000000000000000000000000000000;
    }

    /***********************************|
    |        User Interactions          |
    |__________________________________*/

    function mintFromPass(address _to) public  {
        require(mintpassContractAddress != 0x0000000000000000000000000000000000000000, "AP: Invalid NFT contract address");
        // Verify call is from MintPass contract
        require(mintpassContractAddress == msg.sender, "AP: Only MintPass contract can mint from pass");
        // Mint to pass owner
        uint256 nftId = performMint(_to, 0);
        // Emit minted event
        emit evtNftMintedFromPass(mintpassContractAddress, nftId, _to);
    }

    function performMint(address _to, uint _salePrice) private returns (uint256) {
        uint256 nftId = tokenCount;
        _mint(_to, tokenCount);
        // Set the ownership of this token to sender
        tokenToAddress[tokenCount] = _to;
        // Push associated data for mint to NFT array
        passes.push(Pass({
            minter:  _to,
            sale_price: _salePrice
        }));

        // Increment token count
        tokenCount++;
        return nftId;
    }
    /***********************************|
    |        Admin                      |
    |__________________________________*/

    function setMintpassContractAddress(address _mpAddress) public {
        require( hasRole(MINTER_ROLE, _msgSender()), "Only minter can set address." );
        mintpassContractAddress = _mpAddress;
    }

    /***********************************|
    |    Utility Functions              |
    |__________________________________*/


    /***********************************|
    |    Nullify Functions              |
    |__________________________________*/

}
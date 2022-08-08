// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//                                                                                  '                   /(      .·´    (
//          (`·.                  )\                 (`·.              ')\                      )\      )  `·._):::.    )        ’'
//            )  `·.      .·´( .·´  (                 )  `·.   .·´( .·´  ('               )\ .·´ .:`·.(:;;  --  ' '\:. :(.·´)    )\
//    .·´( .·´:..::(,__(::..--  ' '\:·´('     .·´( .·´:..::(,(::--  ' '\:·.·´('        .·´  (,): --  ' '              \....:::`·.(  (
//    );; :--  ' ’                  _\::/     );; :--   ’             _\::.. `·.)`·. ):.::/\                        ¯¯¯`·’ ::·´
//.·´/\                   ,.. : ´:::'/:’ ’ .·´/\                ,..:´:::'/)::::..::::( `·:/::::\...:´/       ____          \
//)/:::'\__..:´/       /::::::::::/   ' ' )/:::'\...:´/         `·;:;;:/·· ´´ ¯¯¯/’    \::::/::::/      /::::::::/\         'I’
// \:::/:::::·'/       /:::;;::· ´'         \:::/::::/                            '/        \/;::-'/      /::::::::/:::I       ’/
//  '\/;::::-'/       /· ´                   '\/;::-'/       /:·,       .·´/      /'              /I      I¯¯¯¯¯\::'/..-::::/    ’'
//   (`·.)':/       /'                      (`·.)':/       /:::/      /::/      /              /::I       ` * · . ____
//     ):./       /'                '         ):./       /`·;/      /:·/      /'              I:::/`:::·...              /’   '
//    '\:/       /'                          '\:/       /   /      /  /      /                I:/::::::::::::·-,       ’/'
//     /       /'                 '           /____/   /      '/  /      /                  ` ·::;;::- ··  ´´      /'         '
//   '/,..::·´/'                             /:::::-  ´´  ,  - ´´´     .·´'/            /\¯¯¯¯         ,,  -:::::'/'
// '/:::::::'/                             /::`*..¸..-:/:`*..¸..-::::::::/           /::::\,,  -::::´´::::::::::::/''
///:;:: · ´'                       '      /:::::::/::/:::::::/::::::::- ´´           '\:::/:::::::::::::::;;::-·´´'                 '
// ¯                                   ’'`*-::;/::::`*-::;/::::-·· ´´                '\/::::::;;::-· ´´'

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TMS is ERC721A, Ownable {
    using SafeMath for uint256;

    //Tokenomics
    uint256 public maxSupply = 10000;
    uint256 public maxOwnerReserve = 100;

    //Public Mint
    bool public mintActive = false;
    uint256 public maxBatchMintAmount = 20;
    uint256 public mintPrice;

    // Start Index
    uint256 public startingIndexBlock;
    uint256 public startingIndex;

    // URI
    string public baseURI;

    /**
    * @dev The Monks Syndicate
	*/
    constructor(string memory initialBaseUri) ERC721A("The Monks Syndicate", "TMS")
    {
        baseURI = initialBaseUri;
    }

    /**
    * @dev Public mint.
	*/
    function mintTms(uint256 _num_tokens) external payable
    {
        require(mintActive, "Mint is not active.");
        require(_num_tokens <= maxBatchMintAmount, "Cannot mint more than max allowed in a single transaction");
        require(msg.value == mintPrice.mul(_num_tokens), "Transaction value does not match the total required mint price.");
        require(totalSupply().add(_num_tokens) <= maxSupply, "Cannot mint more than max supply of tokens.");

        _safeMint(msg.sender, _num_tokens);

        if (startingIndexBlock == 0 && (totalSupply() == maxSupply))
        {
            startingIndexBlock = block.number;
        }
    }

    function reserve(address to, uint256 _num_tokens) external onlyOwner {
        require(totalSupply().add(_num_tokens) <= maxOwnerReserve, "Cannot mint more than max reserved for owners.");

        _safeMint(to, _num_tokens);
    }

    /**
    * @dev Toggle Mint state.
	*/
    function toggleMint() external onlyOwner
    {
        mintActive = !mintActive;
    }

    /**
    * @dev Set the price of one token.
	*/
    function setMintPrice(uint256 _price) external onlyOwner
    {
        mintPrice = _price;
    }

    /**
    * @dev Finalize starting index and BaseURI.
	*/
    function finalizeStartIndexAndSetBaseURI(string memory _newBaseURI) external onlyOwner
    {
        finalizeStartingIndex();

        baseURI = _newBaseURI;
    }


    /**
    * @dev Get the Base URI.
	*/
    function _baseURI() internal view virtual override returns (string memory)
    {
        return baseURI;
    }

    /**
    * @dev Get the Token URI.
	*/
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseUri = _baseURI();
        uint256 tokenIdWithOffset = ((tokenId + startingIndex) % maxSupply);
        return bytes(baseUri).length != 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenIdWithOffset), '.json')) : '';
    }

    /**
     * @dev Finalize starting index.
	 */
    function finalizeStartingIndex() internal onlyOwner
    {
        require(startingIndex == 0, "Starting index already set.");
        require(startingIndexBlock != 0, "Starting index block must be set.");

        startingIndex = uint256(blockhash(startingIndexBlock)) % maxSupply;

        if (block.number.sub(startingIndexBlock) > 255)
        {
            startingIndex = uint256(blockhash(block.number.sub(1))) % maxSupply;
        }

        if (startingIndex == 0)
        {
            startingIndex = startingIndex.add(1);
        }
    }


    /**
     * @dev Set the starting index block for the collection and unblock setting starting index.
	 */
    function emergencySetStartingIndexBlock() external onlyOwner
    {
        require(startingIndex == 0, "Starting index already set.");

        startingIndexBlock = block.number;
    }

    /**
    * @dev Withdraw the balance from the contract.
	*/
    function withdraw() external onlyOwner
    {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw.");
        payable(msg.sender).transfer(balance);
    }

}
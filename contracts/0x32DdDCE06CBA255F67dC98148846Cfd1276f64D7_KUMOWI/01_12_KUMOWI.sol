// SPDX-License-Identifier: MIT

//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//::::::::::::::::::::::::::::::::::(J+JJJJ+JJJJ-:::::::::::::::::::::::::::::::::
//::~:~:~::~:~::~::~:~::~:~::((+gMH"""77?!~`!?7"TWNgJ_::~:::~::~:::~:::~:::~::~:::
//:::::::~::::~::~::::~::::(M#"`                    7HNJ::::::::::::::::~:::::::::
//:~::~::::~:::::::~:::::(MD                           TMm/::~::~:~:~:::::~::~:~::
//::~:::~::(JJggNg&J_:~([email protected]                               (Mm_:::::::::~:::::::::::
//:::::::(d#=`     7Mm(M$                                  TN/:~:::~::::~:::~:::~:
//::~:::+#'          JMF                                    ?N-::::::::::::::~::::
//::::[email protected]                                                    4N_:(((((:~::~:::::::
//:~::(M\                                                     MY""""""WNgJ:::::~::
//::::(M_                                                               .TNg:~::::
//:::::M[                                                                  TN-::::
//::~::?N,        M]     .M                                                 dN_:~:
//::::::?MNJ      M]     .M                                                  MP:::
//:::::(M"!`                                                                 J#:::
//::~:dD          ?NJ.   &#^                                                 .N:::
//:::(#              ?7"!                                                    (#:::
//:::dF                                                                     .M%:::
//:~:JN                                                                    .MC::::
//::::Mp                                                                .JM5::::~:
//::::(Hm.                                                    `.NNgggNMMBC::::::::
//:~::::?Mm.           .,                                   `.ME:::::::::::::~::::
//::~::~::?TMN+.....JMM57Ma,                              .+M5<:::::::::~:::~::~::
//::::~::::::::<??<>::::::(THMNJ..                   ..JM#5<::::::~::~::::~:::::~:
//:~::::~:::::::::::::~::::::::(7TMMNgJ(.........+gMMBY::::::~:~:::~::~::~:::~::::
//::~::~::~~:~::~::~:::~:~:::::::::::::::<<<<<<<::::::::::::::~::~::::::~:::~::~::
//::~::::~::::~::~::~:::~::~:~::~::~:::::::::::::::::::~:~::~::::::~::~:::::::::::

pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/Counters.sol";
import "@openzeppelin/[email protected]/utils/Strings.sol";

contract KUMOWI is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /**
     * @dev The base URI of metadata 
     */ 
    string private baseTokenURI = "ipfs://Qmf9puo7GyfzENQc2DxhCu4L3VQumeft3zJRikXfa3SxZa/";

    /**
     * @dev Address of the fund manager
     */
    address private fundManager;

    Counters.Counter private _tokenIdCounter;

    constructor(address defaultFundManager) 
    ERC721("KUMOWI", "KUMOWI") {
        fundManager = defaultFundManager;
    }

    /**
     * @dev Set baseTokenURI.
     * @param newBaseTokenURI The value being set to baseTokenURI.
     */
    function setBaseTokenURI(string calldata newBaseTokenURI) external onlyOwner {
        baseTokenURI = newBaseTokenURI;
    }

    /**
     * @dev Set the address of the fund manager contract.
     * @param contractAddr Address of the contract managing funds.
     */
    function setFundManagerContract(address contractAddr) external onlyOwner {
        require(contractAddr != address(0), "invalid address");
        fundManager = contractAddr;
    } 

    /**
     * @dev Mint NFT to fund manager address
     */
    function mint() public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(fundManager, tokenId);
    }

    /**
     * @dev Make metadata URI
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
    }
}
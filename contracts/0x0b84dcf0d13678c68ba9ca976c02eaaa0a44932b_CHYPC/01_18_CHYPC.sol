// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IHYPCSwap.sol";
import "../interfaces/IHYPC.sol";
import "../interfaces/ICHYPC.sol";

/** 
@title  HyperCycle Containerized HyPC ERC721 contract.
@author Barry Rowe, David Liendo
@notice This is the containerized version of the HyPC ERC20 token. Any holder of HyPC
        can swap 2^19 (ie: 524288) HyPC for 1 c_HyPC token, and redeem 1 c_HyPC for 524288
        HyPC. c_HyPC can be assigned to a license (done via a string assignement), which
        is provides proof that this license is backed by a sufficient amount of HyPC.
@dev    The numbering system for the c_HyPC tokenIds comes from the Earth64 global tree,
        starting at the far left 27th level in the binary tree with, corresponding to
        2^26 (67108864) as the node number, with each sequential number corresponding to
        the next node to the right on that 27th level, with a maximum number of nodes
        being 4096. Note that 4096*524288 = 2^31 is the total supply of HyPC tokens.
*/
contract CHYPC is ERC721Enumerable, Ownable, ICHYPC {
    uint256 private startNumber;
    uint256 private endMinted;
    uint256 private mintLimit;
    bool private inited;

    mapping(uint256 => string) public assignmentData;

    IHYPCSwap private HYPCSwapContract;
    IHYPC private HYPCContract;

    /// @notice As stated above, the number system starts at 2^26.
    uint256 public constant CHYPC_START_NUMBER = 67108864;

    /**
        @notice Event for when a token is given a new assignment string.
        @param  owner: the address that made this new assignement
        @param  tokenId: the c_HyPC that has this new assignement.
    */
    event Assigned(address indexed owner, uint256 indexed tokenId);

    //Modifiers
    /**
        @dev Since there is an dependence between multiple contracts, both the Swap and c_HyPC
             contract can not be fully initialized until both are deployed, so we have a
             isInited modifier to check for this initialization.
    */
    modifier isInited {
        require(inited, "Must be initialized.");
        _;
    }

    /// @dev This is a common check for if tokenId is a valid minted token. See mint()
    modifier tokenMinted(uint256 tokenId) {
        require(tokenId >= startNumber && tokenId < endMinted, "Token not yet minted.");
        _;
    }

    /// @dev As stated above, not much happens in the constructor since we need the Swap
    ///      address to finish the initialization. 
    constructor() ERC721("C_HyPC.19", "C_HyPC.19") {
    }

    /**
        @dev   Once the Swap contract has been created as well, we can assign then initialize
               this contract and populate the contract interfaces.
        @param swapAddress: Swap contract's deployed address.
        @param HYPCAddress: The previously deployed HyPC token.
        @param totalTokens: The total amount of tokens that can be minted. Will be 4096 
               on mainnet but 4 for the test suite so we don't have to mint 4k tokens.
    */
    function initContract(address swapAddress, address HYPCAddress, uint256 totalTokens) external onlyOwner {
        require(swapAddress != address(0), "swapAddress must not be the zero address");
        require(HYPCAddress != address(0), "HYPCAddress must not be the zero address");
        require(totalTokens <= 4096, "totalTokens too high, should be 4096");
        require(!inited, "Must not yet be initialized");

        inited = true;
        startNumber = CHYPC_START_NUMBER;
        endMinted = startNumber;
        mintLimit = startNumber+totalTokens;
        HYPCSwapContract = IHYPCSwap(swapAddress);
        HYPCContract = IHYPC(HYPCAddress);
    }

    /// @dev   Mints the c_HyPC in batches, and deposits them into the Swap contract directly.
    /// @param number: the number of tokens to mint in this batch.
    function mint(uint256 number) external onlyOwner isInited {
        require(number > 0, "Number of tokens must be positive");
        require(endMinted+number <= mintLimit, "Can not mint beyond mintLimit.");
        uint256 _i;
        for (_i = 0; _i < number; _i++) {
            uint256 tokenId = endMinted;
            _mint(address(HYPCSwapContract), tokenId);
            assignmentData[tokenId] = "";
            endMinted += 1;
            HYPCSwapContract.addNFT(tokenId);
        }
    }

    /**
        @notice This burns a tokens along with a string assignment. This can be used for chain transfer event
                or an upgrade mechanism to a new token.
        @dev    The assignment string mapping is reused for the burn string in this case, since string
                assignments are only valid while the token is alive.
        @param  tokenId: the token to burn
        @param  data: the burn string to use.
    */
    function burn(uint256 tokenId, string memory data) external isInited {
        require(ownerOf(tokenId) == msg.sender, "Must be owner to burn.");
        assignmentData[tokenId] = data;
        _burn(tokenId);
    }

    /**
        @notice This assigns a string to the token. This is typically the license that this c_HyPC is going
                to back inside the HyperCycle ecosystem. 
        @param  tokenId: the token to make this assignment to.
        @param  data: the string for the assignment.
    */
    function assign(uint256 tokenId, string memory data) external isInited {
        address tokenOwner = ownerOf(tokenId);
        require(tokenOwner == msg.sender, "Owner must assign.");
        assignmentData[tokenId] = data;
        
        emit Assigned(tokenOwner, tokenId);
    }

    /// @notice Returns the assignment string for a token that is not burned.
    /// @param  tokenId: the token to get the assignment of.
    /// @return Assignment string
    function getAssignment(uint256 tokenId) external isInited tokenMinted(tokenId) view returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token is burned.");
        return assignmentData[tokenId];
    }

    /// @notice Returns the burn string for this a token that is burned.
    /// @param  tokenId: the token to get the burn data of.
    /// @return BurnData string
    function getBurnData(uint256 tokenId) external isInited tokenMinted(tokenId) view returns (string memory) {
        require(_ownerOf(tokenId) == address(0), "Token not burned.");
        return assignmentData[tokenId];
    }
}
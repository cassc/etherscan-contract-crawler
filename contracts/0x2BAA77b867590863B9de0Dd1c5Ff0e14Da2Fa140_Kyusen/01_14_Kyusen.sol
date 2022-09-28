//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IKyusen.sol";

//
//                                        +*##%@+
//                                        =--:.  .::            -:
//                                ..: .=+=      [email protected]@%       %*   %+  ..
//                  ...--=:     .%@@: [email protected]@#      [email protected]@%      *%-**#@@#*+-
//      .---    .#@@*  [email protected]@@+   [email protected]@%.  [email protected]@#      [email protected]@%    .#@*   #@@#.
//      [email protected]@#   [email protected]@%:    .%@@#[email protected]@#    [email protected]@#      [email protected]@%    .=%* .%=%[email protected]+.
//      [email protected]@# -%@@=        [email protected]@@@@+     [email protected]@#      [email protected]@%      %*+%- %+ .+=
//      [email protected]@%#@@*.          :@@@+      [email protected]@%      *@@#      %*:   @+
//      [email protected]@@@@*             #@@=      [email protected]@@=.  :*@@%.      =-    .
//      [email protected]@@%@@@+           #@@=       [email protected]@@@@@@@%=
//      [email protected]@# -#@@@*.        #@@=         :-==-:
//      [email protected]@#   :*@@@*.      -=-.                 ::-        . .: =:-:
//      =%#+     ...                 -=+=       [email protected]@%     #[email protected]:%- @=:*.
//                      ==+*##%@@#   @@@@%:     [email protected]@%     +#+#*%[email protected]#*#+
//         :+*%%%%*=.   @@@%#*++=:   @@@@@@*    [email protected]@%     ##*@+%*=%*-+
//       .#@@#+++#@*    @@@-         @@@-#@@@-  [email protected]@%     ##[email protected]+%+ [email protected]%.
//       #@@*           @@@+-==++    @@@: -%@@#:[email protected]@%     ==*@++*:#@*-*
//       [email protected]@@@#+=:      @@@@@@@%*    @@@:   [email protected]@@%@@%    :[email protected]::##:.*#:
//        .-+#%@@@@#.   @@@=         @@@:    .#@@@@%       .-
//              :#@@#   @@@-  ..::   @@@:      [email protected]@%#
//       .*-.   :%@@=   @@@@@@@@@#   ##*.
//      :@@@@@@@@@%-    **+==-::.
//        :=+++=-.
//
//
//

/**
 * @title Implementation of Kyusen Contract.
 * @author @KyusenOfficial Dev Team
 */

contract Kyusen is ERC721, Ownable, ReentrancyGuard {
    event AuxContractUpdate(
        address auxEvoContractAddr,
        address newAuxEvoContractAddr
    );
    event EvoGenerationUpdate(uint256 oldGeneration, uint256 newGeneration);

    /**
     * @dev Amount reserved for the team
     */
    uint256 internal constant RESERVED_SUPPLY = 200;

    /**
     * @dev Max supply that can be minted
     */
    uint256 public maxSupply;

    /**
     * @dev How much per maiden to mint
     */
    uint256 public mintPrice;

    /**
     * @dev Net total maidens minted
     */
    uint256 public totalSupply;

    /**
     * @dev How many has been minted for current sale phase
     */
    uint256 public currentPhaseMinted;

    /**
     * @dev How many maidens can be minted per sale phase
     */
    uint256 internal supplyPerPhase;

    /**
     * @dev Merkle root for allowlists
     */
    using MerkleProof for bytes32[];
    bytes32 private merkleRoot;

    /**
     * @dev For token uri
     */
    string public baseTokenURI;

    /**
     * @dev Emergency overried to disable allowlists from Sale Phase 1 & 2 (so we don't have to switch phases, affecting maiden generations)
     */
    bool internal allowlistRestriction = true;

    /**
     * @dev Enable/disable stasis function for holders
     */
    bool internal allowChangeStasis = true;

    /**
     * @dev Enable/disable claiming permanence for holders
     */
    bool internal allowClaimPermanence = true;

    /**
     * @dev Stop sale temporarily when true
     */
    bool internal salePaused;

    /**
     * @dev Sale phase, 0: none, 1+: phase 1 onwards
     */
    uint256 public currentMintPhase;

    /**
     * @dev What is the evolution generation at now
     */
    uint256 public currentEvoGeneration;

    /**
     * @dev Address for supporting future evolution contract plugins
     */
    address private auxEvoContractAddr;

    /**
     * @dev Packed data describing evolution and mint details for each maiden
     */
    //[0]       Stasis Flag (0: Off, 1: On)
    //[1..4]    Mint Phase
    //[5..18]   Mint Serial
    //[19..255] Evolution and Generation Flags
    mapping(uint256 => uint256) public maidenData;

    /**
     * @dev These masks will zero out unneeded values in conjuction with the packed data above
     */
    uint256 private constant GENERATION_MASK = 524287;
    uint256 private constant SERIAL_MASK = 31;

    /**
     * @dev Constructor for Kyusen Contract
     * @param _maximumSupply The max supply for the duration of mint
     * @param _mintPrice The starting sale price
     * @param _maxSupplyPerPhase The max supply for each sale phase
     */
    constructor(
        uint256 _maximumSupply,
        uint256 _mintPrice,
        uint256 _maxSupplyPerPhase
    ) ERC721("Kyusen", "KYUSEN") {
        maxSupply = _maximumSupply;
        mintPrice = _mintPrice;
        supplyPerPhase = _maxSupplyPerPhase;
    }

    /**
     * @dev This modifier will check if the token is valid (1-9000) and we still have enough tokens
     */
    modifier mintCompliance(uint256 _tokenId) {
        require(_tokenId > 0 && _tokenId < maxSupply + 1, "Invalid token");
        require(
            totalSupply + RESERVED_SUPPLY < maxSupply,
            "Collection Sold out"
        );
        _;
    }

    /**
     * @dev This modifier will allow access only for either the owner or the auxilliary evolution contract.
     */
    modifier onlyOwnerORAuxEvolutionContract() {
        require(
            (auxEvoContractAddr == _msgSender() &&
                auxEvoContractAddr != address(0)) || owner() == _msgSender(),
            "Not Owner or Aux Contract"
        );
        _;
    }

    /********************/
    /*  MAIN FUNCTIONS  */
    /********************/

    /**
     * @dev Return the token URI for the id provided
     * @param _tokenId the maiden token id we will get the URI for
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    "/",
                    Strings.toString(currentEvoGeneration),
                    "/",
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    /**
     * @dev Returns whether the caller is included in the current allowlist
     * @param _merkleProof Signature used to validate the allowlist spot of the caller
     */
    function getIncludedInAllowlist(bytes32[] calldata _merkleProof)
        external
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            );
    }

    /**
     * @dev Turns on phase 1 mint (Presale for Top Activity Users)
     * @param _newMerkleRoot the merkle root we will use for this sale phase
     */
    function openPresale(bytes32 _newMerkleRoot) external onlyOwner {
        require(currentMintPhase != 1, "Phase already set");
        salePaused = false;
        currentMintPhase = 1;
        currentPhaseMinted = 0;
        setMerkleRoot(_newMerkleRoot);
    }

    /**
     * @dev Turns on phase 2 mint (Inner Circle + Sakura Council Only)
     * @param _newMerkleRoot the merkle root we will use for this sale phase
     */
    function openAllowlistSale(bytes32 _newMerkleRoot) external onlyOwner {
        require(currentMintPhase != 2, "Phase already set");
        salePaused = false;
        currentMintPhase = 2;
        currentPhaseMinted = 0;
        setMerkleRoot(_newMerkleRoot);
    }

    /**
     * @dev Turns on phase 3 mint (Public Sale)
     * @param _newPhase the starting phase for this sale, should be 3 or higher
     * @param _mintPrice the new mint price
     */
    function openPublicSale(uint256 _newPhase, uint256 _mintPrice)
        external
        onlyOwner
    {
        require(
            _newPhase >= 3 && currentMintPhase != _newPhase,
            "Phase already set"
        );

        mintPrice = _mintPrice;
        salePaused = false;
        currentPhaseMinted = 0;
        currentMintPhase = _newPhase;
    }

    /**
     * @dev Pause all sales
     */
    function pauseSale() external onlyOwner {
        salePaused = true;
    }

    /**
     * @dev Resume all sales
     */
    function resumeSale() external onlyOwner {
        salePaused = false;
    }

    /**
     * @dev Set the token base URI
     * @param _newBaseURI The new base URI value (do not include a trailing slash!)
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @dev Manually set the merkle root
     * @param _merkleRoot The new merkle root
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev Manually set the max supply per phase
     * @param _supply The new max supply per phase
     */
    function setSupplyPerPhase(uint256 _supply) external onlyOwner {
        supplyPerPhase = _supply;
    }

    /**
     * @dev Manually set the mint price
     * @param _mintPrice The new mint price
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * @dev Manually set the net max supply
     * @param _maximumSupply The new net max supply
     */
    function setMaxSupply(uint256 _maximumSupply) external onlyOwner {
        require(_maximumSupply >= totalSupply, "Value can't be lower than minted");
        maxSupply = _maximumSupply;
    }

    /**
     * @dev Enable allowlist restriction for sale phase 1 & 2
     */
    function enableAllowlistRestriction() external onlyOwner {
        allowlistRestriction = true;
    }

    /**
     * @dev Disable allowlist restriction for sale phase 1 & 2
     */
    function disableAllowlistRestriction() external onlyOwner {
        allowlistRestriction = false;
    }

    /******************/
    /*     MINTER     */
    /******************/

    /**
     * @dev Mint a specific maiden for allowlisted users
     * @param _merkleProof Signature used to validate the allowlist spot of the minter
     * @param _tokenId Maiden's token id being minted.
     */
    function allowlistMint(bytes32[] calldata _merkleProof, uint256 _tokenId)
        external
        payable
        mintCompliance(_tokenId)
        nonReentrant
    {
        require(!salePaused && currentMintPhase != 0, "Sale is disabled");
        require(
            currentMintPhase == 1 || currentMintPhase == 2,
            "Allowlist Mint disabled"
        );

        require(msg.value >= mintPrice, "Pricing error");

        require(
            MerkleProof.verify(
                _merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ) || !allowlistRestriction,
            "Allowlist verification failed"
        );

        totalSupply = totalSupply + 1;
        currentPhaseMinted = currentPhaseMinted + 1;
        maidenData[_tokenId] |= currentMintPhase << 1;
        maidenData[_tokenId] |= totalSupply << 5;

        _safeMint(msg.sender, _tokenId);
    }

    /**
     * @dev Mint a specific maiden for non-allowlisted users
     * @param _tokenId Maiden's token id being minted.
     */
    function publicMint(uint256 _tokenId)
        external
        payable
        mintCompliance(_tokenId)
        nonReentrant
    {
        require(!salePaused && currentMintPhase != 0, "Sale is disabled");
        require(currentMintPhase >= 3, "Public sale disabled");

        require(msg.value >= mintPrice, "Pricing error");

        totalSupply = totalSupply + 1;
        currentPhaseMinted = currentPhaseMinted + 1;
        maidenData[_tokenId] |= currentMintPhase << 1;
        maidenData[_tokenId] |= totalSupply << 5;

        if (
            currentPhaseMinted + 1 > supplyPerPhase &&
            totalSupply + RESERVED_SUPPLY < maxSupply
        ) {
            currentPhaseMinted = 0;
            currentMintPhase = currentMintPhase + 1;
        }

        _safeMint(msg.sender, _tokenId);
    }

    /**
     * @dev Admin minting for emergencies and the remaining reserved 200 maidens
     * @param _tokenId Maiden's token id being minted.
     * @param _receiver The recipient address
     * @param _phase What the sale phase for this maiden data is going to be
     */
    function mintForAddress(
        uint256 _tokenId,
        address _receiver,
        uint256 _phase
    ) external onlyOwner {
        require(_tokenId > 0 && _tokenId < maxSupply + 1, "Invalid token");
        totalSupply = totalSupply + 1;
        maidenData[_tokenId] |= _phase << 1;
        maidenData[_tokenId] |= totalSupply << 5;
        _safeMint(_receiver, _tokenId);
    }

    /******************/
    /*    EVOLUTION   */
    /******************/

    /**
     * @dev Set maiden to stasis so it will not change metadata during seasonal events
     * @param _tokenId Maiden's token id to be put on stasis
     * @param _state True: set stasis to ON, False: set stasis to OFF
     */
    function setStasis(uint256 _tokenId, bool _state) external {
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "Must own token to set status"
        );
        require(allowChangeStasis, "Stasis changing disabled");
        uint256 _maidenData = maidenData[_tokenId];
        if (_state) {
            maidenData[_tokenId] = _maidenData | 1;
        } else {
            maidenData[_tokenId] = _maidenData & ~uint256(1);
        }
    }

    /**
     * @dev Write a seasonal event into the maiden data to "claim" the event as a permanent change.
     * @param _tokenId Maiden token id
     */
    function claimPermanence(uint256 _tokenId) external {
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "Must own token to set status"
        );
        require(allowClaimPermanence, "Evo claiming is disabled");
        uint256 _maidenData = maidenData[_tokenId];
        uint256 _currentEvoGeneration = (currentEvoGeneration << 19);
        maidenData[_tokenId] =
            (GENERATION_MASK & _maidenData) |
            _currentEvoGeneration;
    }

    /**
     * @dev Set the contract's current generation
     * @param _generation Generation to set (Gen 0, Gen 1, so on so forth)
     * @param _allowClaimPermanence Set if we will be allowing this generation to be claimable
     */
    function setEvoGeneration(
        uint256 _generation,
        bool _allowClaimPermanence
    ) external onlyOwnerORAuxEvolutionContract {
        uint256 oldEvoGeneration = currentEvoGeneration;
        currentEvoGeneration = _generation;
        allowClaimPermanence = _allowClaimPermanence;
        emit EvoGenerationUpdate(oldEvoGeneration, _generation);
    }

    /**
     * @dev Allow stasis setting for holders
     */
    function allowStasisChange() external onlyOwnerORAuxEvolutionContract {
        allowChangeStasis = true;
    }

    /**
     * @dev Pause all stasis changes for holders
     */
    function pauseStasisChange() external onlyOwnerORAuxEvolutionContract {
        allowChangeStasis = false;
    }

    /**
     * @dev Allow all evo claiming for holders
     */
    function allowEvoClaiming() external onlyOwnerORAuxEvolutionContract {
        allowClaimPermanence = true;
    }

    /**
     * @dev Pause all evo claiming for holders
     */
    function pauseEvoClaiming() external onlyOwnerORAuxEvolutionContract {
        allowClaimPermanence = false;
    }

    /**
     * @dev Return the current sale phase
     */
    function getMaidenMintPhase(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        uint256 _maidenData = maidenData[_tokenId];
        return (SERIAL_MASK & _maidenData) >> 1;
    }

    /**
     * @dev Return the requested maiden's last saved generation
     * @param _tokenId The maiden we're querying
     */
    function getMaidenGeneration(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        uint256 _maidenData = maidenData[_tokenId];
        return _maidenData >> 19;
    }

    /**
     * @dev Returns the maiden's stasis state
     * @param _tokenId The maiden we're querying
     */
    function getMaidenStasis(uint256 _tokenId) external view returns (uint256) {
        uint256 _maidenData = maidenData[_tokenId];
        return (1 & _maidenData);
    }

    /**
     * @dev Returns the maiden's mint serial number
     * @param _tokenId The maiden we're querying
     */
    function getMaidenMintSerial(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        uint256 _maidenData = maidenData[_tokenId];
        return (GENERATION_MASK & _maidenData) >> 5;
    }

    /**
     * @dev Manually set the maiden's saved generation
     * @param _tokenId The maiden token id we will update
     * @param _newGeneration The new generation value
     */
    function setMaidenGeneration(uint256 _tokenId, uint256 _newGeneration)
        external
        onlyOwnerORAuxEvolutionContract
    {
        uint256 _data = maidenData[_tokenId];
        _newGeneration = _newGeneration << 19;
        maidenData[_tokenId] = (GENERATION_MASK & _data) | _newGeneration;
    }

    /**
     * @dev Manually set the maiden's packed data
     * @param _tokenId The maiden token id we will update
     * @param _newData The new packed data
     */
    function setMaidenData(uint256 _tokenId, uint256 _newData)
        external
        onlyOwnerORAuxEvolutionContract
    {
        maidenData[_tokenId] = _newData;
    }

    /**
     * @dev set the auxilliary evolution contract address, this is for future-proofing the contract
     * @param _newAuxEvoContractAddr The evolution plugin contract address
     */
    function setAuxEvolutionContract(address _newAuxEvoContractAddr)
        external
        onlyOwner
    {
        require(_newAuxEvoContractAddr != address(0), "Invalid address");
        auxEvoContractAddr = _newAuxEvoContractAddr;
        emit AuxContractUpdate(auxEvoContractAddr, _newAuxEvoContractAddr);
    }

    /**
     * @dev returns the auxilliary evolution contract address
     */
    function getAuxEvolutionContract() external view returns (address) {
        return auxEvoContractAddr;
    }

    /******************/
    /*   ACCOUNTING   */
    /******************/
    /**
     * @dev Withdraw funds from this contract to the owner's wallet
     */
    function withdrawAll() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        (bool callSuccess, ) = payable(owner()).call{value: balance}("");

        require(callSuccess, "Withdrawal error");
    }
}
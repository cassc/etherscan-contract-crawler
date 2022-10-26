// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "PaymentSplitter.sol";
import "Pausable.sol";
import "ERC721AWithRoyalties.sol";

abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual;
}

abstract contract ContractGlossary {
    function getAddress(string memory name)
        public
        view
        virtual
        returns (address);
}

abstract contract VRF {
    function rollDice(uint256 num_req, address to)
        public
        virtual
        returns (uint256);
}

contract Horse is ERC721AWithRoyalties, Pausable, PaymentSplitter {
    uint256 _tokenIdCounter;
    address private ExtMintAddress;
    address private HorsePassAddress;
    address private FarmAddress;
    address private LienedFarmAddress;
    string public _baseTokenURI;
    uint256[] private tokenIDs;

    uint256 public _maxSupply;

    ContractGlossary private Index;

    mapping(uint256 => Stable) public stables;
    //maps horse id to farm id
    mapping(address => Request) private requests;

    event HorseStabled(uint256 horseID, uint256 stableID, uint256 stableTerm);

    struct Request {
        uint256[] ids;
        uint256 requestID;
        uint256[] randNums;
        bool freeMint;
    }
    struct Stable {
        uint256 farmID;
        uint256 expDate;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint256 maxSupply,
        address[] memory payees,
        uint256[] memory shares,
        address royaltyRecipient,
        uint256 royaltyAmount,
        address indexContract
    )
        ERC721AWithRoyalties(
            name,
            symbol,
            maxSupply,
            royaltyRecipient,
            royaltyAmount
        )
        PaymentSplitter(payees, shares)
    {
        Index = ContractGlossary(indexContract);

        _baseTokenURI = baseTokenURI;

        _maxSupply = maxSupply;
        _tokenIdCounter = 0;
    }

    function setIndexContract(address contractAddress) public onlyOwner {
        Index = ContractGlossary(contractAddress);
    }

    function resetTokenIDs() public onlyOwner {
        tokenIDs = new uint256[](0);
    }

    function addTokenIDs(uint256 start, uint256 stop) external onlyOwner {
        for (uint256 i = start; i < stop; i++) {
            tokenIDs.push(i);
        }
    }

    function addRandNums(address to, uint256[] memory ids)
        external
        whenNotPaused
    {
        require(msg.sender == Index.getAddress("VRFV2"));
        requests[to].randNums = ids;
    }

    function refreshContracts() internal {
        FarmAddress = Index.getAddress("Farm");
        LienedFarmAddress = Index.getAddress("LienedFarm");
        HorsePassAddress = Index.getAddress("HorsePass");
    }

    function setExtMintAddress(address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "CANNOT BE NULL ADDRESS");
        ExtMintAddress = contractAddress;
    }

    function preMint(uint256 num) external onlyOwner {
        _safeMint(address(this), num);
    }

    function _reqSeed(uint256 num_req) internal returns (uint256) {
        VRF VRFV2 = VRF(Index.getAddress("VRFV2"));
        uint256 requestID = VRFV2.rollDice(num_req, msg.sender);
        return requestID;
    }

    function mintTransferReq(uint256[] memory ids) external whenNotPaused {
        refreshContracts();
        ERC721 HorsePassContract = ERC721(HorsePassAddress);
        uint256 idsLen = ids.length;
        for (uint256 i = 0; i < idsLen; i++) {
            require(
                HorsePassContract.ownerOf(ids[i]) == msg.sender,
                "MUST OWN ALL HORSE MINT PASSES"
            );
        }
        requests[msg.sender].ids = ids;
        requests[msg.sender].requestID = _reqSeed(ids.length);
    }

    function mintTransferFul() public whenNotPaused {
        uint256[] memory ids = requests[msg.sender].ids;
        uint256[] memory randnums = requests[msg.sender].randNums;
        delete requests[msg.sender];
        refreshContracts();
        ERC721 HorsePassContract = ERC721(HorsePassAddress);
        uint256 idsLen = ids.length;
        for (uint256 i = 0; i < idsLen; i++) {
            uint256 len = tokenIDs.length;
            uint256 tokenID = tokenIDs[((randnums[i] % len))];
            require(
                HorsePassContract.ownerOf(ids[i]) == msg.sender,
                "MUST OWN ALL HORSE MINT PASSES"
            );
            tokenIDs[((randnums[i] % len))] = tokenIDs[len - 1];
            tokenIDs.pop();
            _transferFrom(address(this), msg.sender, tokenID);
            HorsePassContract.transferFrom(msg.sender, address(this), ids[i]);
        }
    }

    function adminMintTransferReq(uint256 num) public onlyOwner {
        requests[msg.sender].ids = [num];
        requests[msg.sender].requestID = _reqSeed(num);
    }

    function adminMintTransferFul(address to) public onlyOwner {
        uint256[] memory ids = requests[msg.sender].ids;
        uint256[] memory randnums = requests[msg.sender].randNums;
        uint256 uintI = ids[0];
        for (uint256 i = 0; i < uintI; i++) {
            uint256 len = tokenIDs.length;
            uint256 tokenID = tokenIDs[((randnums[i] % len))];
            _transferFrom(address(this), to, tokenID);
            tokenIDs[((randnums[i] % len))] = tokenIDs[len - 1];
            tokenIDs.pop();
        }
        delete requests[msg.sender];
    }

    function extMint(address to, uint256 amount_req) external whenNotPaused {
        require(
            msg.sender == ExtMintAddress,
            "Must be called from External Mint Contract"
        );
        _safeMint(to, amount_req);
        _tokenIdCounter += amount_req;
    }

    function freeMintVoSTransferReq(address to, uint256 amount_req)
        external
        whenNotPaused
    {
        require(
            msg.sender == Index.getAddress("LienedFarm"),
            "Must be called from LIENEDFARM Contract"
        );
        requests[to].ids = [amount_req];
        requests[to].requestID = _reqSeed(amount_req);
        requests[to].freeMint = true;
    }

    function freeMintVOSTransferFul() external whenNotPaused {
        require(
            requests[msg.sender].freeMint,
            "MUST BE FREEMINT TO USE THIS FUNCTION"
        );
        uint256[] memory ids = requests[msg.sender].ids;
        uint256[] memory randnums = requests[msg.sender].randNums;
        uint256 uintI = ids[0];
        for (uint256 i = 0; i < uintI; i++) {
            uint256 len = tokenIDs.length;
            _transferFrom(
                address(this),
                msg.sender,
                tokenIDs[((randnums[i] % len))]
            );
            tokenIDs[((randnums[i] % len))] = tokenIDs[len - 1];
            tokenIDs.pop();
        }
        delete requests[msg.sender];
    }

    function setStable(
        uint256 horseID,
        uint256 farmID,
        uint256 stableTerm
    ) external whenNotPaused {
        refreshContracts();
        require(msg.sender == FarmAddress, "MUST BE CALLED FROM FARM CONTRACT");
        stables[horseID] = Stable(farmID, stableTerm);
        emit HorseStabled(horseID, farmID, stableTerm);
    }

    function setBaseUri(string memory baseUri) external onlyOwner {
        _baseTokenURI = baseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI));
    }

    function mint(address to, uint256 count) external onlyOwner {
        _safeMint(to, count);
    }

    function checkStable(uint256 horseID) external view returns (uint256) {
        return stables[horseID].farmID;
    }

    function checkStableExp(uint256 horseID) external view returns (uint256) {
        return stables[horseID].expDate;
    }

    function MAX_TOTAL_MINT() external view returns (uint256) {
        return _maxSupply;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
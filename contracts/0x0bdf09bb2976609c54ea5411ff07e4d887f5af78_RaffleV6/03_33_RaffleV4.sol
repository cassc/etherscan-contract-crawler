//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./RaffleV3.sol";
import "./interfaces/IERC721Key.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

contract RaffleV4 is RaffleV3 {
    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256) private _balanceOf;
    mapping(uint256 => bool) public keyNFTClaimed;    

    IERC721 public genesisNft;

    IERC721Key public keyNFT;
    uint256 public GENESIS_OFFSET;

    mapping(uint256 => bool) public isGenesis;
    ERC1155Upgradeable public openseaStoreFront;

    function initializeV4() public reinitializer(4) {
        GENESIS_OFFSET = 10000;
    }

    function isClaimed(uint256 id) public view override returns (bool) {
        return keyNFTClaimed[id];
    }

    function KeyApiensClaim(
        uint256[] calldata ids_
    )
        external
        whenNotPaused
        nonReentrant
    {
        require(keyClaimLive, "Not live");
        uint256 length = ids_.length;

        for(uint256 i = 0; i < length; i++) {
            uint256 current = ids_[i];
            require(_tokenToOwner[current] == msg.sender, "Not Owner");
            require(!isClaimed(current), "Already claimed");
            keyNFTClaimed[current] = true;
        }

        keyNFT.mint(
            msg.sender,
            length
        );
    }

    function KeyGenesisClaim(
        uint256[] calldata ids_
    )
        external
        whenNotPaused
        nonReentrant
    {
        require(keyClaimLive, "Not live");
        uint256 length = ids_.length;

        for(uint256 i = 0; i < length; i++) {
            uint256 current = ids_[i];
            require(ownerOf(current) == msg.sender, "Not Owner");
            require(!isClaimed(current + GENESIS_OFFSET), "Already claimed");
            keyNFTClaimed[current + GENESIS_OFFSET] = true;
        }

        keyNFT.mint(
            msg.sender,
            length
        );
    }

    function setGenesis(IERC721 genesisNft_) external onlyOwner {
        genesisNft = genesisNft_;
    }

    function ownerOf(uint256 id_) public view returns (address) {
        return _ownerOf[id_];
    }

    function balanceOf(address owner_) public view returns (uint256) {
        return _balanceOf[owner_];
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[11] memory genesis = [
                84060628940425386830944862847235387962585941726956624089304862393769836675073,
                84060628940425386830944862847235387962585941726956624089304862386073255280641,
                84060628940425386830944862847235387962585941726956624089304862388272278536193,
                84060628940425386830944862847235387962585941726956624089304862390471301791745,
                84060628940425386830944862847235387962585941726956624089304862382774720397313,
                84060628940425386830944862847235387962585941726956624089304862391570813419521,
                84060628940425386830944862847235387962585941726956624089304862389371790163969,
                84060628940425386830944862847235387962585941726956624089304862392670325047297,
                84060628940425386830944862847235387962585941726956624089304862383874232025089,
                84060628940425386830944862847235387962585941726956624089304862387172766908417,
                84060628940425386830944862847235387962585941726956624089304862384973743652865
            ];

            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i = 0; tokenIdsIdx != tokenIdsLength; i++) {
                currOwnershipAddr = ownerOf(genesis[i]);
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = genesis[i];
                }
            }
            return tokenIds;
        }
    }

    function overrideTokenToOwner(uint256[] calldata ids_, address from_, address to_) external onlyOwner {
        uint256 length = ids_.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 id_ = ids_[i];
            require(from_ == _tokenToOwner[id_], "Check from");
            _tokenToOwner[id_] = to_;
            emit Staked(to_, id_);
        }
    }

    function overrideOwnerOf(uint256[] calldata ids_, address from_, address to_) external onlyOwner {
        uint256 length = ids_.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 id_ = ids_[i];
            require(from_ == _ownerOf[id_], "Check from");
            _ownerOf[id_] = to_;
            _balanceOf[from_]--;
            _balanceOf[to_]++;
        }        
    }

    function stakeGenesis(uint256[] calldata ids_) external whenNotPaused nonReentrant {
        require(!claimLive, "Claim is live");
        require(stakeLive, "Stake is not live");
        uint256 length = ids_.length;

        for (uint256 i = 0; i < length; i++) {
            uint256 current = ids_[i];
            require(isGenesis[current], "Not Genesis");
            _ownerOf[current] = msg.sender;            
            openseaStoreFront.safeTransferFrom(msg.sender, address(this), current, 1, "");
        }
        _balanceOf[msg.sender] += length;
        totalSupply += length;
    }

    function unstakeGenesis(uint256[] calldata ids_)
        external
        nonReentrant
        whenNotPaused
    {
        require(false, "Disabled");
    }

    function unstakeGenesisV2(uint256[] calldata ids_) 
        external
        nonReentrant
        whenNotPaused
    {
        require(!claimLive, "Claim is live");
        require(unstakeLive, "UnStake is not live");
        uint256 length = ids_.length;

        for (uint256 i = 0; i < length; i++) {
            uint256 current = ids_[i];
            require(ownerOf(current) == msg.sender, "Not Owner");
            delete _ownerOf[current];
            openseaStoreFront.safeTransferFrom(address(this), msg.sender, current, 1, "");
        }
        _balanceOf[msg.sender] -= length;
        totalSupply -= length;
    }

    function setKeyNFT(IERC721Key keyNFT_) external onlyOwner {
        keyNFT = keyNFT_;
    }

    function release(uint256[] calldata)
        external
        override
        whenNotPaused
        virtual
        nonReentrant
    {
        require(false, "This function has been disabled");
    }

    function seedGenesis(uint256[] calldata ids_) external onlyOwner {
        for(uint256 i = 0; i < ids_.length; i++) {
            isGenesis[ids_[i]] = true;
        }
    }

    function setOpenseaStoreFront(ERC1155Upgradeable openseaStoreFront_) external onlyOwner {
        openseaStoreFront = openseaStoreFront_;
    }
}
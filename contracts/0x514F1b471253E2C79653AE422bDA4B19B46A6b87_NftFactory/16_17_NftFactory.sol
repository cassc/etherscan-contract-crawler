// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import '../base/Ownable.sol';
import '../base/IERC20.sol';
import "../base/ERC721.sol";
import "../base/IMetadata.sol";
import "../base/IGameEngine.sol";
import "../base/Counters.sol";
import "../base/IVRF.sol";
import "./ProxyTarget.sol";
// import "hardhat/console.sol";

contract NftFactory is Ownable, ERC721, ProxyTarget {

    using Strings for uint;

	bool public initialized;
    ////nfts
    mapping (uint => address) public tokenOwner;
    // mapping (uint=>uint) public actionTimestamp;

    //COUNTS
    using Counters for Counters.Counter;
    Counters.Counter private tokenId_;

    //SALES
    bool public revealed;
    uint public SUP_THRESHOLD;

    //AMOUNT
    uint[2] public amount;

    //CONTRACT
    IGameEngine game;
    IERC20 SUP;
    IMetadata metadataHandler;
    IVRF randomNumberGenerated;

    // ------------------------ DATA END

    function initialize(address _gameAddress, address _tokenAddress,address _metadata,address _vrf) external {
        require(msg.sender == _getAddress(ADMIN_SLOT), "not admin");
        require(!initialized);
        initialized = true;

        _name   = "HungerBrainz";
        _symbol = "HBZ";
        _owner  = msg.sender;

        revealed = false;
        SUP_THRESHOLD = 1000;

        game = IGameEngine(_gameAddress);
        SUP = IERC20(_tokenAddress);
        metadataHandler = IMetadata(_metadata);
        randomNumberGenerated = IVRF(_vrf);
    }

    function currentTokenID() external view returns(uint){
        return tokenId_.current();
    }

    function tokenOwnerSetter(uint tokenId, address owner_) external {
        require(_msgSender() == address(game));
        tokenOwner[tokenId] = owner_;
    }

    function setContract(address _gameAddress, address _tokenAddress, address _metadata,address _vrf) external onlyOwner {
        game = IGameEngine(_gameAddress);
        SUP = IERC20(_tokenAddress);
        metadataHandler = IMetadata(_metadata);
        randomNumberGenerated = IVRF(_vrf);
    }

    function burnNFT(uint tokenId) external {
        require (_msgSender() == address(game), "Not GameAddress");
        _burn(tokenId);
    }

    function setRevealed(bool revealed_) external onlyOwner{
        revealed = revealed_;
    }

    function setSupThreshold(uint newThreshold) external onlyOwner {
        SUP_THRESHOLD = newThreshold;
    }

    function mintReserve(uint8 tokenType, uint tokenAmount, address receiver) external onlyOwner {
        require(tokenType < 2,"Invalid type");
        require(tokenId_.current() <= SUP_THRESHOLD,"Buy using SUP");
        amount[tokenType] = amount[tokenType]+tokenAmount;
        for (uint i =0;i<tokenAmount;i++) {
            tokenId_.increment();
            _safeMint(receiver,  tokenId_.current());
            metadataHandler.addMetadata(1,tokenType,tokenId_.current());
            tokenOwner[tokenId_.current()]=receiver;
        }
    }

    function buyUsingSUPAndStake(bool stake, uint8 tokenType, uint tokenAmount) external {
    //  By calling this function, you agreed that you have read and accepted the terms & conditions
    // available at this link: https://hungerbrainz.com/terms
       require(tokenType < 2,"Invalid type");
       require(tokenId_.current() > SUP_THRESHOLD,"Buy using Eth");
        SUP.transferFrom(_msgSender(), address(this), tokenAmount*1000 ether);
        SUP.burn(tokenAmount* 1000 ether); //1000 ether
        amount[tokenType] = amount[tokenType]+tokenAmount;

        // if (isApprovedForAll(_msgSender(),address(game))==false) {
        //     setApprovalForAll(address(game), true);
        // }

        for (uint i=0; i< tokenAmount; i++) {
            if (stake) {
                tokenId_.increment();
                _safeMint(address(game), tokenId_.current());
                metadataHandler.addMetadata(1,tokenType,tokenId_.current());
                game.alertStake(tokenId_.current());
            } else {
                tokenId_.increment();
                _safeMint(msg.sender,tokenId_.current());
                metadataHandler.addMetadata(1,tokenType,tokenId_.current());
            }
            tokenOwner[tokenId_.current()]=msg.sender;
        }
    }

    function tokenOwnerCall(uint tokenId) external view returns (address) {
        return tokenOwner[tokenId];
    }

    function withdraw() public payable onlyOwner {
        address w1 = 0x9EdA6A5Cb5A986c290b655E7b5DfdB86E8258CE4;
        require(msg.sender == w1 || msg.sender == _getAddress(ADMIN_SLOT), "no permission");
        (bool success, ) = payable(w1).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    //Better if Game Address directly calls metadata contract
    function restrictedChangeNft(uint tokenID, uint8 nftType, uint8 level) external  {
        require(msg.sender == address(game),"Call restricted");

        (uint8 nftTypeOld,)=metadataHandler.getToken(tokenID);
        if(nftTypeOld != nftType) {
            amount[nftType]++;
            amount[nftTypeOld]--;
        }

        metadataHandler.changeNft(tokenID,nftType,level);
    }


    //#endregion
    function tokenURI(uint tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        require(revealed == true, "Not revealed yet");
        return metadataHandler.getTokenURI(tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint tokenId
    ) internal override{
        if(to!=address(game) && to!=tokenOwner[tokenId]){
            tokenOwner[tokenId] = to;
        }
        super._transfer(from,to,tokenId);
    }

    function _mint(address to, uint tokenId) internal override{
        super._mint(to,tokenId);
        // actionTimestamp[tokenId] = randomNumberGenerated.getCurrentIndex();
    }

    function _burn(uint tokenId) internal override {
        (uint8 nftType,)=metadataHandler.getToken(tokenId);
        amount[nftType]--;
        tokenOwner[tokenId] = address(0);
        super._burn(tokenId);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     * game address is always approved for all
     */
    function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
    {
        return 
            (operator == address(game)) || 
            super.isApprovedForAll(owner, operator);
    }


    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) internal virtual override {
        _transfer(from, to, tokenId);
        // require(
        //     _checkOnERC721Received(from, to, tokenId, _data),
        //     "ERC721: transfer to non ERC721Receiver implementer"
        // );
    }

}
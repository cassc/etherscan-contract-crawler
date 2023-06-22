// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "erc721a/contracts/ERC721A.sol";
import "./lib/rarible/royalties/contracts/LibPart.sol";
import "./lib/rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "./lib/rarible/royalties/contracts/RoyaltiesV2.sol";

contract EVERGIRL is ERC721A, Ownable, ReentrancyGuard, RoyaltiesV2 {
    mapping(address => uint256) public whiteLists_phase1;
    mapping(address => uint256) public whiteLists_phase2;
    uint256 private _phase1_whiteListCount;
    uint256 private _phase2_whiteListCount;

    uint256 public tokenAmount = 0;
    uint256 public mintPrice_phase1 = 0.02 ether;
    uint256 public mintPrice_phase2 = 0.02 ether;
    uint256 public mintPrice_phase3 = 0.03 ether;

    bool public startPhase1Sale = false;
    bool public startPhase2Sale = false;
    bool public startPhase3Sale = false;

    bool public revealed = false;

    uint256 private maxMintsPhase1 = 1;
    uint256 private maxMintsPhase3PerTx = 5;

    uint256 private _totalSupply = 3333;
    string private _beforeTokenURI;
    string private _afterTokenPath;

    mapping(address => uint256) public phase1Minted;
    mapping(address => uint256) public phase2Minted;

    // Royality management
    bytes4 public constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    address payable public defaultRoyaltiesReceipientAddress; // This will be set in the constructor
    uint96 public defaultPercentageBasisPoints = 1000; // 10%

    constructor(address _royaltiesReceipientAddress) ERC721A("EVERGIRL", "EG") {
        defaultRoyaltiesReceipientAddress = payable(
            _royaltiesReceipientAddress
        );
    }

    function ownerMint(uint256 amount, address _address) public onlyOwner {
        require((amount + tokenAmount) <= (_totalSupply), "mint failure");

        _safeMint(_address, amount);
        tokenAmount += amount;
    }

    function phase1Mint(uint256 amount) external payable nonReentrant {
        require(startPhase1Sale, "sale: Paused");
        require(
            whiteLists_phase1[msg.sender] >= phase1Minted[msg.sender] + amount,
            "You have no wl left"
        );

        require(
            msg.value == mintPrice_phase1 * amount,
            "Value sent is not correct"
        );
        require((amount + tokenAmount) <= (_totalSupply), "mint failure");

        phase1Minted[msg.sender] += amount;
        _safeMint(msg.sender, amount);
        tokenAmount += amount;
    }

    function phase2Mint(uint256 amount) external payable nonReentrant {
        require(startPhase2Sale, "sale: Paused");
        require(
            whiteLists_phase2[msg.sender] >= phase2Minted[msg.sender] + amount,
            "You have no wl left"
        );
        require(
            msg.value == mintPrice_phase2 * amount,
            "Value sent is not correct"
        );
        require((amount + tokenAmount) <= (_totalSupply), "mint failure");

        phase2Minted[msg.sender] += amount;
        _safeMint(msg.sender, amount);
        tokenAmount += amount;
    }

    function phase3Mint(uint256 amount) public payable nonReentrant {
        require(startPhase3Sale, "sale: Paused");
        require(maxMintsPhase3PerTx >= amount, "sale: 5 maxper tx");
        require(
            msg.value == mintPrice_phase3 * amount,
            "Value sent is not correct"
        );
        require((amount + tokenAmount) <= (_totalSupply), "mint failure");

        _safeMint(msg.sender, amount);
        tokenAmount += amount;
    }

    function setMintPricePhase1(uint256 newPrice) external onlyOwner {
        mintPrice_phase1 = newPrice;
    }

    function setMintPricePhase2(uint256 newPrice) external onlyOwner {
        mintPrice_phase2 = newPrice;
    }

    function setMintPricePhase3(uint256 newPrice) external onlyOwner {
        mintPrice_phase3 = newPrice;
    }

    function setReveal(bool bool_) external onlyOwner {
        revealed = bool_;
    }

    function setStartPhase1Sale(bool bool_) external onlyOwner {
        startPhase1Sale = bool_;
    }

    function setStartPhase2Sale(bool bool_) external onlyOwner {
        startPhase2Sale = bool_;
    }

    function setStartPhase3Sale(bool bool_) external onlyOwner {
        startPhase3Sale = bool_;
    }

    function setBeforeURI(string memory beforeTokenURI_) public onlyOwner {
        _beforeTokenURI = beforeTokenURI_;
    }

    function setAfterURI(string memory afterTokenPath_) public onlyOwner {
        _afterTokenPath = afterTokenPath_;
    }

    function setTotalSupply(uint256 newTotalSupply) external onlyOwner {
        _totalSupply = newTotalSupply;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return _beforeTokenURI;
        } else {
            return
                string(
                    abi.encodePacked(
                        _afterTokenPath,
                        Strings.toString(tokenId),
                        ".json"
                    )
                );
        }
    }

    function deletePhase1WL(address addr) public virtual onlyOwner {
        _phase1_whiteListCount =
            _phase1_whiteListCount -
            whiteLists_phase1[addr];
        delete (whiteLists_phase1[addr]);
    }

    function deletePhase2WL(address addr) public virtual onlyOwner {
        _phase2_whiteListCount =
            _phase2_whiteListCount -
            whiteLists_phase2[addr];
        delete (whiteLists_phase2[addr]);
    }

    function upsertPhase1WL(address addr, uint256 maxMint)
        public
        virtual
        onlyOwner
    {
        _phase1_whiteListCount =
            _phase1_whiteListCount -
            whiteLists_phase1[addr];
        whiteLists_phase1[addr] = maxMint;
        _phase1_whiteListCount = _phase1_whiteListCount + maxMint;
    }

    function upsertPhase2WL(address addr, uint256 maxMint)
        public
        virtual
        onlyOwner
    {
        _phase2_whiteListCount =
            _phase2_whiteListCount -
            whiteLists_phase2[addr];
        whiteLists_phase2[addr] = maxMint;
        _phase2_whiteListCount = _phase2_whiteListCount + maxMint;
    }

    function pushMultiPhase1WLSpecifyNum(address[] memory list, uint256 num)
        public
        virtual
        onlyOwner
    {
        for (uint256 i = 0; i < list.length; i++) {
            whiteLists_phase1[list[i]] = num;
            _phase1_whiteListCount += num;
        }
    }

    function pushMultiPhase2WLSpecifyNum(address[] memory list, uint256 num)
        public
        virtual
        onlyOwner
    {
        for (uint256 i = 0; i < list.length; i++) {
            whiteLists_phase2[list[i]] = num;
            _phase2_whiteListCount += num;
        }
    }

    function getPhase1WLCount() public view returns (uint256) {
        return _phase1_whiteListCount;
    }

    function getPhase2WLCount() public view returns (uint256) {
        return _phase2_whiteListCount;
    }

    function getPhase1WL(address _address) public view returns (uint256) {
        return whiteLists_phase1[_address] - phase1Minted[msg.sender];
    }

    function getPhase2WL(address _address) public view returns (uint256) {
        return whiteLists_phase2[_address] - phase2Minted[msg.sender];
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @dev disable Ownerble renounceOwnership
     */
    function renounceOwnership() public override onlyOwner {}

    /**
     * @dev do withdraw eth.
     */
    function withdrawETH() external virtual onlyOwner {
        uint256 royalty = address(this).balance;

        Address.sendValue(payable(owner()), royalty);
    }

    // Copied from ForgottenRunesWarriorsGuild. Thank you dotta ;)
    /**
     * @dev ERC20s should not be sent to this contract, but if someone
     * does, it's nice to be able to recover them
     * @param token IERC20 the token address
     * @param amount uint256 the amount to send
     */
    function forwardERC20s(IERC20 token, uint256 amount) public onlyOwner {
        require(address(msg.sender) != address(0));
        token.transfer(msg.sender, amount);
    }

    // Royality management
    /**
     * @dev set defaultRoyaltiesReceipientAddress
     * @param _defaultRoyaltiesReceipientAddress address New royality receipient address
     */
    function setDefaultRoyaltiesReceipientAddress(
        address payable _defaultRoyaltiesReceipientAddress
    ) public onlyOwner {
        defaultRoyaltiesReceipientAddress = _defaultRoyaltiesReceipientAddress;
    }

    /**
     * @dev set defaultPercentageBasisPoints
     * @param _defaultPercentageBasisPoints uint96 New royality percentagy basis points
     */
    function setDefaultPercentageBasisPoints(
        uint96 _defaultPercentageBasisPoints
    ) public onlyOwner {
        defaultPercentageBasisPoints = _defaultPercentageBasisPoints;
    }

    /**
     * @dev return royality for Rarible
     */
    function getRaribleV2Royalties(uint256)
        external
        view
        override
        returns (LibPart.Part[] memory)
    {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = defaultPercentageBasisPoints;
        _royalties[0].account = defaultRoyaltiesReceipientAddress;
        return _royalties;
    }

    /**
     * @dev return royality in EIP-2981 standard
     * @param _salePrice uint256 sales price of the token royality is calculated
     */
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (
            defaultRoyaltiesReceipientAddress,
            (_salePrice * defaultPercentageBasisPoints) / 10000
        );
    }

    /**
     * @dev Interface
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}
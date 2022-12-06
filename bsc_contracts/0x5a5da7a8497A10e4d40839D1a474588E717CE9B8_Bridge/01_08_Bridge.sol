// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import "./Interfaces/IBridgeFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "erc721a/contracts/ERC721A.sol";

contract Bridge is ERC721A, Ownable {
    address public BUSD;

    uint256 public maxSupply;
    uint256 public maxPerWallet;
    uint256 public maxPreSale;
    uint256 public nftPrice;
    uint256 public projectId;

    uint256 public immutable SCALE = 100;

    bool public easyTransfer;
    bytes32 private merkleRoot;
    string public baseTokenUri;

    bool public isPresaleStage;

    uint256[] public discountQuantities;
    address[] public mintingDistributionRecipients;
    address[] public nftHolders;

    event UpdateMaxPerWallet(uint256 projectid, uint256 newMax);
    event UpdatedNftPrice(uint256 projectid, uint256 newPrice);
    event UpdatedMerkleRoot(bytes32 oldRoot, bytes32 newRoot);
    event InitalDistributionRecipients(uint256 projectId, address[] recipients, uint256[] percentages);
    event AdjustedDistributionRecipient(
        address newRecipient,
        uint256 recipientPercentage,
        address[] recipients,
        uint256[] percentages
    );
    event ProjectDeployed(
        address projectAddress,
        uint256 projectId,
        uint256 price,
        uint256 supply,
        uint256 maxAmountPerWallet,
        uint256 maxPreSale,
        bool hasPresale
    );
    event UpdatedTokenURI(string oldURI, string newURI);
    event PublicSaleActivated();
    event UpdatedMaxPreSale(uint256 projectid, uint256 newMax);
    event TokensMinted(address owner, uint256 projectid, uint256 price, uint256 quantity);
    event TokenTransfered(address from, address to, uint256 tokenId, uint256 projectId);

    mapping(address => uint256) public addressToDistributionPercentage;
    mapping(uint256 => uint256) public discountQuantityToPercentage;
    mapping(address => uint256) public numberOfMintedNFTSPerUser;

    constructor(
        uint256 _projectid,
        address paymentTokenAddress,
        bool[] memory _booleans,
        string[] memory _tokenDetails,
        uint256[] memory _quantities,
        bytes32 _merkleRoot,
        uint256[] memory _discountQuantites,
        uint256[] memory _discountPercentages,
        address[] memory _mintingDistributionRecipients,
        uint256[] memory _recipientsMintingPercentage,
        address _newOwner
    ) ERC721A(_tokenDetails[0], _tokenDetails[1]) {
        _transferOwnership(_newOwner);

        BUSD = paymentTokenAddress;

        isPresaleStage = _booleans[0];
        easyTransfer = _booleans[1];

        maxSupply = _quantities[0];
        maxPerWallet = _quantities[1];
        nftPrice = _quantities[2];
        maxPreSale = _quantities[3];
        projectId = _projectid;

        merkleRoot = _merkleRoot;
        discountQuantities = _discountQuantites;
        mintingDistributionRecipients = _mintingDistributionRecipients;

        baseTokenUri = _tokenDetails[2];

        for (uint256 x = 0; x < _discountPercentages.length; x++) {
            discountQuantityToPercentage[_discountQuantites[x]] = _discountPercentages[x];
        }
        for (uint256 x = 0; x < _recipientsMintingPercentage.length; x++) {
            addressToDistributionPercentage[_mintingDistributionRecipients[x]] = _recipientsMintingPercentage[x];
        }

        emit ProjectDeployed(address(this), _projectid, nftPrice, maxSupply, maxPerWallet, maxPreSale, isPresaleStage);
        emit InitalDistributionRecipients(_projectid, _mintingDistributionRecipients, _recipientsMintingPercentage);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? baseURI : "";
    }

    //----------------------------------------------------------------------------------------------------------------------
    //---------------------------------------------STATE-CHANGING FUNCTIONS-------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------

    function preMint(
        uint256 _quantity,
        uint256 _price,
        bytes32[] calldata _merkleProof
    ) external {
        require(isPresaleStage, "Not in presale");
        require(super.balanceOf(msg.sender) + _quantity <= maxPreSale, "Above max presale amount");
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))),
            "Invalid merkle proof"
        );

        _mint(_quantity, _price);
    }

    function publicMint(uint256 _quantity, uint256 _price) external {
        require(!isPresaleStage, "Not in public mint");

        _mint(_quantity, _price);
    }

    /**
     * @param _newRecipientArray holds the new recipient at index 0, the addresses following are current recipients who's percentages have changed
     * @param _newRecipientPercentages holds the new recipients percentage at index one with the following percentages aligning with the above recipients
     */
    function addAddressToMintingProceeds(
        address _newRecipient,
        uint256 _newPercentage,
        address[] memory _newRecipientArray,
        uint256[] memory _newRecipientPercentages
    ) external onlyOwner {
        uint256 newRecipientArrayLength = _newRecipientArray.length;
        uint256 newPercentagesLength = _newRecipientPercentages.length;
        uint256 totalDistributionPercentages = 0;

        require(newRecipientArrayLength == newPercentagesLength, "Array lengths do not match");
        require(_newRecipient != address(0), "Cannot add address zero");
        require(addressToDistributionPercentage[_newRecipient] == 0, "Recipient already exists");

        for (uint256 x = 0; x < newPercentagesLength; x++) {
            totalDistributionPercentages += _newRecipientPercentages[x];
            require(_newRecipientPercentages[x] <= 100, "Percentage must be less than 100");
            require(_newRecipientPercentages[x] > 0, "Percentage must be bigger than 0");
            require(addressToDistributionPercentage[_newRecipientArray[x]] > 0, "Recipient does not exists");
        }

        //Making sure all distribution uses the full 100%
        require(totalDistributionPercentages == (100 - _newPercentage), "Distribution doesnt equal 100");

        for (uint256 x = 0; x < newRecipientArrayLength; x++) {
            addressToDistributionPercentage[_newRecipientArray[x]] = _newRecipientPercentages[x];
        }

        mintingDistributionRecipients.push(_newRecipient);
        addressToDistributionPercentage[_newRecipient] = _newPercentage;

        emit AdjustedDistributionRecipient(
            _newRecipient,
            _newPercentage,
            mintingDistributionRecipients,
            _newRecipientPercentages
        );
    }

    /**
     * @param _newRecipientArray holds the removed recipient at index 0, the addresses following are current recipients who's percentages have changed
     * @param _newRecipientPercentages number at index 0 is irrelavant and the following percentages aligning with the above recipients
     */
    function removeAddressFromMintingProceeds(
        address _removedAddress,
        address[] memory _newRecipientArray,
        uint256[] memory _newRecipientPercentages
    ) external onlyOwner {
        require(_removedAddress != address(0), "Cannot remove address zero");
        require(addressToDistributionPercentage[_removedAddress] > 0, "Recipient does not exist");

        uint256 newRecipientArrayLength = _newRecipientArray.length;
        uint256 newPercentagesLength = _newRecipientPercentages.length;
        uint256 mintingDistributionRecipientsLength = mintingDistributionRecipients.length;
        uint256 totalDistributionPercentages = 0;
        uint256 removalIndex;

        require(newRecipientArrayLength == newPercentagesLength, "Array lengths do not match");

        for (uint256 x = 0; x < newPercentagesLength; x++) {
            totalDistributionPercentages += _newRecipientPercentages[x];
            require(_newRecipientPercentages[x] <= 100, "Percentage must be less than 100");
            require(_newRecipientPercentages[x] > 0, "Percentage must be bigger than 0");
            require(addressToDistributionPercentage[_newRecipientArray[x]] > 0, "Recipient does not exists");
        }

        require(totalDistributionPercentages == 100, "Distribution doesnt equal 100");

        for (uint256 x = 0; x < mintingDistributionRecipientsLength; x++) {
            if (mintingDistributionRecipients[x] == _removedAddress) {
                removalIndex == x;

                break;
            }
        }

        mintingDistributionRecipients[removalIndex] = mintingDistributionRecipients[
            mintingDistributionRecipientsLength - 1
        ];
        mintingDistributionRecipients.pop();
        addressToDistributionPercentage[_removedAddress] = 0;

        for (uint256 x = 0; x < newRecipientArrayLength; x++) {
            addressToDistributionPercentage[_newRecipientArray[x]] = _newRecipientPercentages[x];
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenID
    ) public payable override(ERC721A) {
        require(easyTransfer == true, "EASY TRANSFER INNACTIVE");
        super.transferFrom(_from, _to, _tokenID);
        emit TokenTransfered(_from, _to, _tokenID, projectId);
    }

    //----------------------------------------------------------------------------------------------------------------------
    //----------------------------------------------------SETTER FUNCTIONS--------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        string memory oldURI = baseTokenUri;
        baseTokenUri = _baseTokenUri;
        emit UpdatedTokenURI(oldURI, _baseTokenUri);
    }

    function setMerkleRoot(bytes32 _newRoot) external onlyOwner {
        bytes32 oldRoot = merkleRoot;
        merkleRoot = _newRoot;
        emit UpdatedMerkleRoot(oldRoot, _newRoot);
    }

    function setMaxPerWallet(uint256 _newMax) external onlyOwner {
        maxPerWallet = _newMax;
        emit UpdateMaxPerWallet(projectId, _newMax);
    }

    function setNFTPrice(uint256 _newPrice) external onlyOwner {
        nftPrice = _newPrice;
        emit UpdatedNftPrice(projectId, _newPrice);
    }

    function setMintPublic() external onlyOwner {
        isPresaleStage = false;
        emit PublicSaleActivated();
    }

    function setPreSale(uint256 _newMax) external onlyOwner {
        maxPreSale = _newMax;
        emit UpdatedMaxPreSale(projectId, _newMax);
    }

    //----------------------------------------------------------------------------------------------------------------------
    //----------------------------------------------------GETTER FUNCTIONS--------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------

    function getDiscountedPrice(uint256 _quantity) public view returns (uint256) {
        uint256 discountPercentage = 0;
        uint256 currentIndex = discountQuantities.length;
        while (currentIndex > 0) {
            currentIndex--;
            if (discountQuantities[currentIndex] <= _quantity) {
                discountPercentage = discountQuantityToPercentage[discountQuantities[currentIndex]];
                break;
            }
        }
        uint256 discount = ((nftPrice * discountPercentage) / SCALE);
        uint256 amountPayable = (nftPrice - discount) * _quantity;
        return amountPayable;
    }

    function getNFTHoldersArray() public view returns (address[] memory) {
        return nftHolders;
    }

    function _mint(uint256 _quantity, uint256 _price) internal {
        require((totalSupply() + _quantity) <= maxSupply, "Mint above max supply");
        require((numberOfMintedNFTSPerUser[msg.sender] + _quantity) <= maxPerWallet, "Above max per wallet");

        uint256 mintingDistributionRecipientsLength = mintingDistributionRecipients.length;
        uint256 amountPayable = getDiscountedPrice(_quantity);
        uint256 _amount;

        require(_price >= amountPayable, "Incorrect payment amount");

        if (numberOfMintedNFTSPerUser[msg.sender] == 0) {
            nftHolders.push(msg.sender);
        }

        numberOfMintedNFTSPerUser[msg.sender] = numberOfMintedNFTSPerUser[msg.sender] + _quantity;
        IERC20(BUSD).transferFrom(msg.sender, address(this), _price);

        for (uint256 x = 0; x < mintingDistributionRecipientsLength; x++) {
            _amount = (_price * addressToDistributionPercentage[mintingDistributionRecipients[x]]) / SCALE;
            bool sent1 = IERC20(BUSD).transfer(mintingDistributionRecipients[x], _amount);
            require(sent1, "FAILED TO SEND BUSD");
        }

        _safeMint(msg.sender, _quantity);
        emit TokensMinted(msg.sender, projectId, _price, _quantity);
    }
}
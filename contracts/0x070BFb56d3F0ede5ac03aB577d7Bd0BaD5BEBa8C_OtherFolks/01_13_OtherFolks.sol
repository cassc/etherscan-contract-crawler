// SPDX-License-Identifier: Unlicense
// Creator: 0xYeety

pragma solidity ^0.8.9;

//            dP   dP                         .8888b          dP dP
//            88   88                         88   "          88 88
// .d8888b. d8888P 88d888b. .d8888b. 88d888b. 88aaa  .d8888b. 88 88  .dP  .d8888b.
// 88'  `88   88   88'  `88 88ooood8 88'  `88 88     88'  `88 88 88888"   Y8ooooo.
// 88.  .88   88   88    88 88.  ... 88       88     88.  .88 88 88  `8b.       88
// `88888P'   dP   dP    dP `88888P' dP       dP     `88888P' dP dP   `YP `88888P'

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OtherFolks is ERC721, Ownable {
    using Address for address;
    using Strings for uint256;

    string public PROVENANCE;
    bool provenanceSet;

    mapping(address => uint256) private _numMinted;

    /*************************************************************************/
    /*** PAYMENT VARIABLES (Start) *******************************************/
    address[] public payees;
    mapping(address => uint256) private paymentInfo;
    uint256 totalReceived = 0;
    mapping(address => uint256) amountsWithdrawn;

    modifier onlyPayee() {
        _isPayee();
        _;
    }
    function _isPayee() internal view virtual {
        require(paymentInfo[msg.sender] > 0, "not a payee");
    }
    /*** PAYMENT VARIABLES (End) *******************************************/
    /***********************************************************************/

    address public allowListContract;
    mapping(uint256 => bool) public tokenIsClaimed;

    uint256 public mintPrice = 0.07 ether;
    uint256 public allowListMintPrice = 0.05 ether;

    enum MintStatus {
        PreMint,
        AllowList,
        Public,
        Finished
    }

    MintStatus public mintStatus = MintStatus.PreMint;

    uint256 public maxPossibleSupply;
    uint256 public maxMintsPerWallet;

    string collectionDescription = "A collection of 146 photos spanning 10 years of street, landscape and portrait photography, available to mint-via-ENS. 'Other Folks' is a companion collection to 'Folks Genesis'";
    string collectionImage = "https://bafkreiez2qjbllhbryyveqmug2mslvkgffyq6r4uo5be6y55gyv3udkbjm.ipfs.nftstorage.link";
    string externalLink = "https://streetphotography.eth.limo";

    constructor (
        string memory name_,
        string memory symbol_,
        uint256 maxPossibleSupply_,
        uint256 maxMintsPerWallet_,
        address allowListContractAddress_,
        address[] memory payees_,
        uint256[] memory basisPoints_
    ) ERC721(name_, symbol_) {
        maxPossibleSupply = maxPossibleSupply_;
        maxMintsPerWallet = maxMintsPerWallet_;
        allowListContract = allowListContractAddress_;

        require(payees_.length == basisPoints_.length, "l");
        payees = payees_;
        for (uint256 i = 0; i < payees_.length; i++) {
            paymentInfo[payees_[i]] = basisPoints_[i];
        }
    }

    /****************************************************************************/
    /*** MINT DETAILS CONTROL (Start) *******************************************/
    function changeMintStatus(MintStatus newMintStatus) public onlyOwner {
        require(mintStatus != MintStatus.PreMint, "pm");
        require(newMintStatus != MintStatus.PreMint && mintStatus != MintStatus.Finished, "ms");

        mintStatus = newMintStatus;
    }

    function setMaxPossibleSupply(uint256 newMPS) public onlyOwner {
        require(mintStatus == MintStatus.PreMint, "ms");

        maxPossibleSupply = newMPS;
    }

    function setMaxMintsPerWallet(uint256 newMMPW) public onlyOwner {
        require(mintStatus == MintStatus.PreMint, "ms");

        maxMintsPerWallet = newMMPW;
    }

    function setMintPrice(uint256 newMintPrice) public onlyOwner {
        require(mintStatus == MintStatus.PreMint, "ms");

        mintPrice = newMintPrice;
    }

    function setAllowListMintPrice(uint256 newAllowListMintPrice) public onlyOwner {
        require(mintStatus == MintStatus.PreMint, "ms");

        allowListMintPrice = newAllowListMintPrice;
    }

    function setName(string memory newName) public onlyOwner {
        require(mintStatus == MintStatus.PreMint, "ms");

        _setName(newName);
    }

    function setSymbol(string memory newSymbol) public onlyOwner {
        require(mintStatus == MintStatus.PreMint, "ms");

        _setSymbol(newSymbol);
    }

    function setDescription(string memory newDescription) public onlyOwner {
        collectionDescription = newDescription;
    }

    function setImage(string memory newImage) public onlyOwner {
        collectionImage = newImage;
    }
    /*** MINT DETAILS CONTROL (End) *******************************************/
    /**************************************************************************/

    function _mintMain(address _to, uint256 _quantity) private {
        require(
            _numMinted[_to] + _quantity <= maxMintsPerWallet &&
            totalSupply() + _quantity <= maxPossibleSupply, "mmpw/mps");

        _safeMint(_to, _quantity);

        if (totalSupply() == maxPossibleSupply) {
            mintStatus = MintStatus.Finished;
        }
    }

    function preMint(address v1Address_) public onlyOwner {
        require(mintStatus == MintStatus.PreMint, "pm");

        ERC721Basic v1Contract = ERC721Basic(v1Address_);
        for (uint256 i = 0; i < v1Contract.totalSupply(); i++) {
            _mintMain(v1Contract.ownerOf(i), 1);
        }

        mintStatus = MintStatus.AllowList;
    }

    function gift(address _to) public onlyOwner {
        require(mintStatus == MintStatus.AllowList || mintStatus == MintStatus.Public, "ms");

        _mintMain(_to, 1);
    }

    function mintPublic(uint256 _quantity) public payable {
        require(msg.value >= (_quantity*mintPrice), "m.v");
        require(mintStatus == MintStatus.Public, "ms");
        totalReceived += msg.value;
        _mintMain(msg.sender, _quantity);
    }

    function mintAllowList(uint256 _quantity) public payable {
        require(ERC721Basic(allowListContract).balanceOf(msg.sender) > 0, "al");
        require(msg.value >= (_quantity*allowListMintPrice), "m.v");
        require(mintStatus == MintStatus.AllowList || mintStatus == MintStatus.Public, "ms");

        totalReceived += msg.value;
        _mintMain(msg.sender, _quantity);
    }

    //////////

    function setPreRevealURI(string memory preRevealURI_) public onlyOwner {
        _setPreRevealURI(preRevealURI_);
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        require(!provenanceSet);
        PROVENANCE = provenanceHash;
        provenanceSet = true;
    }

    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"", name(),"\",",
                "\"description\":\"", collectionDescription, "\",",
                "\"image\":\"", collectionImage, "\",",
                "\"external_link\":\"", externalLink, "\",",
                "\"seller_fee_basis_points\":500,\"fee_recipient\":\"",
                "0x01A29134723ef72a968838cb1DF498BC4f910bEc", "\"}"
            )
        );
    }

    /*********************************************************************/
    /*** PAYMENT LOGIC (Start) *******************************************/
    receive() external payable {
        if (ERC721Basic(allowListContract).balanceOf(msg.sender) > 0) {
            mintAllowList(msg.value/allowListMintPrice);
        }
        else {
            mintPublic(msg.value/mintPrice);
        }
    }

    function withdraw() public onlyPayee {
        uint256 totalForPayee = (totalReceived/10000)*paymentInfo[msg.sender];
        uint256 toWithdraw = totalForPayee - amountsWithdrawn[msg.sender];
        amountsWithdrawn[msg.sender] = totalForPayee;
        (bool success, ) = payable(msg.sender).call{value: toWithdraw}("");
        require(success, "Payment failed!");
    }

    function withdrawTokens(address tokenAddress) external onlyPayee() {
        for (uint256 i = 0; i < payees.length; i++) {
            IERC20(tokenAddress).transfer(
                payees[i],
                (IERC20(tokenAddress).balanceOf(address(this))/10000)*paymentInfo[payees[i]]
            );
        }
    }

    function emergencyWithdrawTokens(address tokenAddress) external onlyOwner() {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }
    /*** PAYMENT LOGIC (End) *******************************************/
    /*******************************************************************/
}

////////////////////

abstract contract ERC721Basic {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function balanceOf(address owner) public view virtual returns (uint256);
    function totalSupply() public view virtual returns (uint256);
}

////////////////////////////////////////
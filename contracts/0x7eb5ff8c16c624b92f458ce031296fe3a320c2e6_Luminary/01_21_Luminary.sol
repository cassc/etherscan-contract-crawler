// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract Luminary is
    Initializable,
    ERC1155Upgradeable,
    IERC2981Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable,
    UUPSUpgradeable
{
    using StringsUpgradeable for uint256;
    address collingsAddress;
    address clientAddress;
    uint256 collingsFee;
    bool publicSaleActive;
    bool artistSaleActive;
    bool whitelistSaleActive;
    uint256 totalSellableAmount;
    address[] whitelistedAddresses;
    address[] artistAddresses;
    uint256 public royalty;
    string public baseUri;
    uint256 public nftPrice;
    string public name;
    string public symbol;
    mapping(address => uint256) numberMinted;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC1155_init("");
        __Ownable_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();

        name = "Luminary";
        symbol = "LMRY";
        baseUri = "https://ipfs.io/ipfs/QmZTn4DS6BKoteAETgFfjxf1YCWwx6KDSmi3Jgv7W7AtpM/";

        collingsAddress = 0x64024942fa38486b375FbaE3a01f767CC47Fcb2f; // Collings
        clientAddress = 0xdE2de1d9DEADC8C2b74ad7c39078824048458B01; // Danielle
        collingsFee = 15; // 15% of the total sellable amount
        totalSellableAmount = 11; // Number of NFTs to sell per picture
        royalty = 100; // 100 is 10%
        nftPrice = 0.22 ether;

        artistAddresses = [
            0x359C6ED49E60a5763Fa69Af218d2715739DFa765,
            0x061B2692300D52e1A32eB2a968DdAB4E7d01167B,
            0x6ea6D15cDE84b1416575fdC3F6400Ca90533226E,
            0x44AD56B79f26BbE75a7E810E862636700780aC98,
            0x951e3F7596982ADb595BA2162e82C2915E5A92AB,
            0x04Df8D02f912d34FEf12a1B0488ee56FD6f7416c,
            0x64024942fa38486b375FbaE3a01f767CC47Fcb2f,
            0xdE2de1d9DEADC8C2b74ad7c39078824048458B01,
            0xE4B4f24F403B08A885861e7c3790c54022b8b6CE,
            0x8dAb1E6b614aA68Cf3c79A8aab7394eFc38561D7,
            0x06e9F3C57e04dfcD38aacaa880169C86E3672557,
            0x470b1036f77a4AaCE5ba18BdBDAC204DE886FFa2,
            0x4FACd26125d4967364CF94d38a29EfC64A326C61,
            0x9d85A0928aC5C6329eac50E27ecb8086600924B0,
            0x7F221Ff7970B93f9c3F44b00EF9d0e364f34c09F
        ];

        whitelistedAddresses = [
            0x35547D74055919b591B4EEA9D24a47bb4388a6A7,
            0x49AFE5b2F5Fb12C943E04eC5Bf331Bd2B5E519cB,
            0x5B81276703FE074090F488F7Ed22C55642cCaE9a,
            0xA96FDC7664B962811CF55f0016bA190bd214c7B9,
            0x4FACd26125d4967364CF94d38a29EfC64A326C61,
            0xbA791AFC7918b9834d6F371ff20109bCE462B0Fd,
            0xcd0A81AB12235aA354F96DE0CD83f8c080324094,
            0x9d3797D2f833E09c28676253203541bA48089660,
            0x721E2C75645411B7d066e3d56fB3f0F8026AC7cb,
            0xFabd1c48fB0ae1D60041E7d288b3e7CFAc8c18cF,
            0x62EeB8039c6215a81a2A94eF446a778386aE75Fc,
            0xCbFFBbF889398360e237ee2bF5c0317379C57639,
            0x921Fb4289317F9a10b1191b2CA6446AA76D58D34,
            0x9aa824A302597E3477d0435cfc5b1e1B9Eb23449,
            0x960e4c8A49e9F5B6D75f16c8Fd92Ca945B4d694f,
            0x9CA2E346CaDbD57f5d242B8B563b0e4D6623E76f,
            0x6fF053A6D87fa201B06bc5A47DA8bc47Fb3A5D54,
            0xAbb75A3F519396E7f0aFA1371a9e650CE82FeE3c,
            0xA96FDC7664B962811CF55f0016bA190bd214c7B9,
            0xe2Cb104Bb61C5710c205865e069c1c2Dc3fB9f4d,
            0x541961679a7735D50415b9E2717E4E20770044BB,
            0xd47190a02f034dEAaeD894783A91d737DfbbcD01,
            0xDBB4D053dF9B7f2Ca9B3213a6a54DEDc06fA15B3,
            0x5C6DDC1335e8cA85F9e81cD90AB571C3f78be97d,
            0x62EeB8039c6215a81a2A94eF446a778386aE75Fc,
            0x1e75D640D970229D3cE4a1e3B80A14498192F166,
            0x27DC66aCd2A5EA322b75e10906812bD988Ca07a7,
            0x297a30822d34aDcF919745cdE2DAcAd0533Dd581,
            0x780d5EF9B1853Cf1a68eA855c8cF866250875C2E,
            0x7468462021f6f09bd3e0317a36D421aED0F06f88,
            0x1116Df452e0826E7AC9dbADd3b43cE7524AA7247,
            0xb1252F0c8FE444557FD494576E9f8a10D3c05502,
            0x70eB68fD12EB0a0877BEfc12A92DF8b55C00D1Ee,
            0x8124eE103C3694Dc0C7C6EFadAEd0a08f63908DD,
            0x5d72e17ECef6eEbb71698A9686d3c618aac71044,
            0x887C306E102396b6e1629205Ac042BDb94A48c46,
            0xb8Fe7081dAECfF4C8a6abBE0f6fC65e9FbA50f5b,
            0x054Fe056070F37318F278dF8f81081b3A24896Ab,
            0xC5b09d17DBa5dC4F8a2E02DE772C00B208e7634a,
            0x7F221Ff7970B93f9c3F44b00EF9d0e364f34c09F,
            0xacC4B6f3Ca8d59f631c1148dCaA52B9D7f5C819A,
            0x04Df8D02f912d34FEf12a1B0488ee56FD6f7416c,
            0x088d83E5B20f900904A08C155eE2857C6F908455,
            0x93E5Bfc551f36C303EEF1ACd5651C62607A5c735,
            0x3a1857bB5c349083E70907e15885fB89108c70CB,
            0xb8Fe7081dAECfF4C8a6abBE0f6fC65e9FbA50f5b,
            0x94Cd499EC56952484Ed7d5E81753028cFb11728b,
            0x721E2C75645411B7d066e3d56fB3f0F8026AC7cb,
            0xb62DcAE8E7d22294182fa9eb951479F8090ABbd1,
            0x02975dE7279F69A48bf607727dfdff009083544f,
            0xf0c3FBF2D5De550d9B9E648dE4fb94c64e6adf07,
            0xBe9998830C38910EF83e85eB33C90DD301D5516e,
            0x167541118486742491e5194309B5479C3935CafD,
            0xAa21f0319BfE388c5Ea97b614157c206d865Cc35,
            0x97e31B4eC56A93958782FCaC016c546e4f1BB472,
            0xe84Db4Cda868f54E49b3b5a8a45d3B05A76C8600,
            0x97e31B4eC56A93958782FCaC016c546e4f1BB472,
            0xF5f6a6e88332A2BCC86D4E05cEf36749d1c6B92F,
            0x762E0D8148c4ac848182bA7dC87CeF187e72C74e,
            0x90ae4E5247e012b3543340C6c5C79b749FF70758,
            0x93E5Bfc551f36C303EEF1ACd5651C62607A5c735,
            0x5bd6555866c66bA9E23d326C9c7d4D45eA44e119,
            0x6732B708f9087BbFB69fe6e00AC783290f77C65A,
            0x3F8cbb3a29EBf90dDf8dA055cE62059a13D25f55,
            0xa50FBf0b07f08d13e5a6A0913D7a15062Af399E1,
            0xb62DcAE8E7d22294182fa9eb951479F8090ABbd1,
            0x0Cb8CA03B94401793eAdC0675cACa229E3F9A7a4,
            0xF5da47208BB8FE003f452569d2dc29Ae1E8fABa6,
            0xBb59bE9193918fFca8242D90e2981570bb1796B2,
            0x9A126eCc0DC4CA6d110D8199842CDD2C2FCBA74D,
            0xBBc5abbF61Ab64ca02BdC973E76bBc528234beF3,
            0xde3dad98701720C51463296c4d91923f98A3F5C9,
            0xA446859f3e5953Fd61F3c94CEbAD5c3B4B0A9d98,
            0x25224DbaE13cc9c1a4325B0Fca08D4ac4f8B4976,
            0x505d92bf94067783dD3ad45897eFA570d00BE917,
            0xf4C005a5dfa203ee835FC45361e2E602F218E4Bc,
            0x4901d86653eea6a7C319e8f667B0e3f66C27c307,
            0x34083a27B01d9C727F9A007065cBFd751284b7f7,
            0x773b360dA7b45c41e1dA7C8dB72503AAD66a2b2A,
            0x727964592Bf66B3f16D8D3a03F2B11a8b0180b45,
            0xb57C2f8bF37585eBDCABa7A823cb99e0dF6bDbDf,
            0xF468350b4982b1E09AEf2F973C7DE492615939F7,
            0x951e3F7596982ADb595BA2162e82C2915E5A92AB,
            0x8326C54221304dcDa643D646B470defb4AEda28a,
            0xA96FDC7664B962811CF55f0016bA190bd214c7B9,
            0xd28a1347d597F363240Cbd5f326C4F262AE7917B,
            0xD16eEa9B7253b4D8345FebCFA098abde69C7af0a,
            0xD16eEa9B7253b4D8345FebCFA098abde69C7af0a,
            0xFa8AbE7D3024a0bf75cB592d7A6126455D91be39,
            0x917524e9454C64B082285019bC2a7079aacB8696,
            0x080866544aFAA670bC9caa2C357a4904dF0D95f0,
            0x95c7B3D58641ca7F1C969Dba19b2a4ebD270A8cC
        ];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setPrice(uint256 _nftPrice) public onlyOwner {
        nftPrice = _nftPrice;
    }

    function activatePublicSale() public onlyOwner {
        publicSaleActive = true;
        artistSaleActive = false;
        whitelistSaleActive = false;
    }

    function activateArtistSale() public onlyOwner {
        publicSaleActive = false;
        artistSaleActive = true;
        whitelistSaleActive = false;
    }

    function activateWhitelistSale() public onlyOwner {
        publicSaleActive = false;
        artistSaleActive = false;
        whitelistSaleActive = true;
    }

    function stopAllSales() public onlyOwner {
        publicSaleActive = false;
        artistSaleActive = false;
        whitelistSaleActive = false;
    }

    function setURI(string memory newuri) public onlyOwner {
        baseUri = newuri;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _artistMint(
        address account,
        uint256 id,
        uint256 amount
    ) internal {
        require(
            isOnList(account, artistAddresses),
            "Address is not on the artist list"
        );
        require(numberMinted[account] < 1, "You can not mint more than 1");
        numberMinted[account] += 1;
        _mint(account, id, amount, "");
    }

    function _publicMint(
        address account,
        uint256 id,
        uint256 amount
    ) internal {
        _mint(account, id, amount, "");
    }

    function _whitelistMint(
        address account,
        uint256 id,
        uint256 amount
    ) internal {
        require(
            isOnList(account, whitelistedAddresses),
            "Address is not on the whitelist"
        );
        _mint(account, id, amount, "");
    }

    function mint(uint256 id, uint256 amount) public payable {
        require(
            totalSupply(id) < totalSellableAmount,
            "Mint amount exceeds total sellable amount"
        );
        require(id > 0 && id <= 11, "Invalid id");
        if (artistSaleActive) {
            _artistMint(msg.sender, id, amount);
        } else if (publicSaleActive) {
            require(msg.value >= nftPrice, "Not enough ETH");
            _publicMint(msg.sender, id, amount);
        } else if (whitelistSaleActive) {
            require(msg.value >= nftPrice, "Not enough ETH");
            _whitelistMint(msg.sender, id, amount);
        } else {
            revert("NFT Sales are not active");
        }
    }

    function ownerMint(uint256 id, uint256 amount) public onlyOwner {
        require(
            totalSupply(id) < totalSellableAmount,
            "Mint amount exceeds total sellable amount"
        );
        require(id > 0 && id <= 11, "Invalid id");
        _mint(msg.sender, id, amount, "");
    }

    function withdraw() external onlyOwner {
        (bool collingsSuccess, ) = payable(collingsAddress).call{
            value: (address(this).balance * collingsFee) / 100
        }("");
        require(collingsSuccess, "Error withdrawing to collings wallet");
        (bool clientSuccess, ) = payable(clientAddress).call{
            value: address(this).balance
        }("");
        require(clientSuccess, "Error withdrawing to client wallet");
    }

    function isOnList(address _user, address[] memory _list)
        public
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < _list.length; i++) {
            if (_list[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function setWhitelist(address[] calldata _users) public onlyOwner {
        whitelistedAddresses = _users;
    }

    function setArtists(address[] calldata _users) public onlyOwner {
        whitelistedAddresses = _users;
    }

    function updateSellableAmount(uint256 amount) public onlyOwner {
        totalSellableAmount = amount;
    }

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override(IERC2981Upgradeable)
        returns (address Receiver, uint256 royaltyAmount)
    {
        return (address(this), (_salePrice * royalty) / 1000);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    baseUri,
                    StringsUpgradeable.toString(id),
                    ".json"
                )
            );
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "Ownable.sol";
import "ReentrancyGuard.sol";
import "ERC721A.sol";
import "Strings.sol";
import "ECDSA.sol";

error AddressNotAllowlistVerified();

/*
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::!*%$%*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::!$SBSSSB##[email protected]*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::$B#***$SB#*$BS!::::!*%$$%*!::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::!$&&$!:::*SBSSBBBB#*%BB*::[email protected]##[email protected]!::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::*SB&#B#!:::!%%#B#%&BBS&*:::*BB%*!!*%#[email protected]::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::SB$*%#B%*&SSS#BS*$BB*::::::[email protected]##&#SBS*::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::!%&###&@$BS%*%#[email protected][email protected]&BS*:::::::::!*[email protected]@@$*!:::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::!#B#&@@&[email protected]@#BBB&***@B#@#&[email protected]&&&&&&&&@$$%*!!::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::*BS*****%$SBBB#&BB&@&SBBSSBBBBBBBBBBBB#@&##SSSS#&$%!:::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::!&B#@%%%%$#B#***$BBBBBBBBBBBBBS%*%&SBBB%:::!!*%$&#SBS&%!:::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::%&SSSSSBBS****%[email protected]%%[email protected]#BBBBBB****%&BB#::::::::::!*$#SB#$*::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::!%$$$$*@B&!***$BB#SSSSSBBBBBBS%****#B&::::::::::::::!%@SB#%!:::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::%#BSSSSS#SBS%$%$BBS#@$%%$#BBBBBBB&%*%SB*:::::::::::::::::!%&[email protected]!:::::::::::::::::::::::::::::
::::::::::::::::::::::::::$BS%***%$&[email protected]**!*!**#B#&SBBBBBBBB%:::::::::::::::::::::[email protected]@!:::::::::::::::::::::::::::
:::::::::::::::::::::::::!SB%!******@B&!::@BS%%%%$&BB&!*@@&BBBBB%::::::::::::::::::::::::[email protected]$::::::::::::::::::::::::::
::::::::::::::::::::::::::&B&%***%%@BB*.:.:SBBBBBBBBBS%*SB&&BB#!:::::::::::::::::::::::::::*&B#*::::::::::::::::::::::::
:::::::::::!*%[email protected]$$%*!::::::@BBBSBBBS#B#*:[email protected]#[email protected]%&BBS$:::::::::::::::::::::::::::::::$BB%:::::::::::::::::::::::
:::::::::$#SBS###[email protected]*:::%[email protected]**$SBBBB&%*%#[email protected]!:::::::::::::::::::::::::::::::::%[email protected]::::::::::::::::::::::
:::::::::@BS*!!!*&##[email protected]!$BBBBBBB&****%BBB*!***%[email protected]!::::::::::::::::!!!::::::::::::::::!*#B&:::::::::::::::::::::
::::::::::@BS$*!!$&#[email protected]!***&BBB#%***%SBBBBB#$!::::::::::::::::*&SBS&*:::::::::::::::!*&B&::::::::::::::::::::
:::::::::::*&SBS#&&#SBSSBBBBBBBBBS%*%&BBBBBB#&&SBBBS&*::::!!!:::::::::::!SBBBBBB&!::::::::::::::!*#B$:::::::::::::::::::
:::::::::::::!*[email protected]@@@$*$BBBBBBBBBBBBBBBBBBBBBBBBBS&%!::::*#BBS&%:::::::::$BBBBBBBB#!:::::::::::::!*%SB*::::::::::::::::::
:::::::::::::::::::::*[email protected]%!::::::*BBBBBBB#*:::::::@BBBBBBBBBS!:::::::::::::!*$BS!:::::::::::::::::
::::::::::::::::::::!SB%#BBBBBBBBBBBBBBBBS&$*!:::::::::&BBBBBBBBB%::::::$BBBBBBBBBB&:::::::::::::!**#B$:::::::::::::::::
::::::::::::::::::::@[email protected]:!$#SBBBBBBSS#&$%!::::::::::::::#BBBBBBBBBB%:::::*BBBBBBBBBBB%:::::::::::::**$BS!::::::::::::::::
:::::::::::!**:::::!BB!::::!!****!!!:::::::::::::::::::#BBBBBBBBBBB*::::!SBBBBBBBBBB#:::::::::::::!**SB*::::::::::::::::
:::::!%@&@#BBS!::::$B&:::::::::::::::::::::::::::::::::@BBBBBBBBBBB#:::::$BBBBBBBBBBB*::::::::::::!**&[email protected]::::::::::::::::
:::!&BB#[email protected]*::::#B%:::::::::::::::::::::::::::::::::*BBBBBBBBBBBB%:::::&BBBBBBBBBB%::::::::::::!**$B&::::::::::::::::
::%[email protected]*&B&*%BB!:::!BB!::::::::::::::::::::::::::::::::::#BBBBBBBBBBB&:::::!#BBBBBBBBB%::::::::::::!**$B#::::::::::::::::
:*BB%[email protected]#!*#[email protected]::::*B#:::::::::::::::::::::::::::::::::::*BBBBBBBBBBBS!:::::!#BBBBBBBB*::::::::::::!**%B#::::::::::::::::
:&B$!!*$!%#B&!::::%B#::::::::::::::::::::::::::::::::::::$BBBBBBBBBBB*::::::[email protected]:::::::::::::!**$B#::::::::::::::::
!BB%**%$#BS$::::::%B#:::::::::::::::::::::::::::::::::::::$BBBBBBBBBB!::::::::!$&#&%::::::::::::::!**@B&::::::::::::::::
!&SSSSSS&%!:::::::*B#::::::::::::::::::::::::::::::::::::::$BBBBBBBB#::::::::::::::::::::::!%*!:::***&B$::::::::::::::::
::!!**!!::::::::::!BS!::::::::::::::::::::::::::::::::::::::*&BBBBBS*::::::::::::::::::::::$SBB&!:***SB*::::::::::::::::
:::::::::::::::::::#B*::::::::::::::::::::::::::::::::::::::::*[email protected]@%!::::::::::::::::::::::::&B&S%!**$B#:::::::::::::::::
:::::::::::::::::::@[email protected]:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%BS!!!***SB%:::::::::::::::::
:::::::::::::::::::!BB!::::::::::::::::::::::::::::!!:::::::::::::::::::::::::::::::::::::*SB*::!**@B&::::::::::::::::::
::::::::::::::::::::@[email protected]:::::::::::::::::::::::::::%S#!:::::::::::::::::::::::::::::::::::%SB%::!**%BB!::::::::::::::::::
::::::::::::::::::::!SB*:::::::::::::::::::::::::$BB$::::::::::::::::::::::::::::::::::[email protected]#*::!**%SB%:::::::::::::::::::
:::::::::::::::::::::%BS!:::::::::::::::::::::::!BB#B#%!:::::::::::::::::::::::::::::*@BB$!::!***#B$::::::::::::::::::::
::::::::::::::::::::::$B#:::::::::::::::::::::::*[email protected]:%#[email protected]*!:::::::::::::::::::::::!$#BS$!:::!**%#[email protected]:::::::::::::::::::::
:::::::::::::::::::::::@B#!::::::::::::::::::::::!::::*$#BS&$%!!::::::::::::!!*$&#BS&%!::::!**%SB$::::::::::::::::::::::
::::::::::::::::::::::::$B#*:::::::::::::::::::::::::::::!%@#SSS##&@@@@@@&&#SSSS&$*!::::::!**$BB%:::::::::::::::::::::::
:::::::::::::::::::::::::%BB%::::::::::::::::::::::::::::::::!*%[email protected]&&&&&&@@$%*!:::::::::!**%#B#*::::::::::::::::::::::::
::::::::::::::::::::::::::*#B&!::::::::::::::::::::::::::::::::::::::::::::::::::::::::!**@BB$::::::::::::::::::::::::::
:::::::::::::::::::::::::::!$BB$!::::::::::::::::::::::::::::::::::::::::::::::::::::!**$SB&!:::::::::::::::::::::::::::
:::::::::::::::::::::::::::::!&BS$!::::::::::::::::::::::::::::::::::::::::::::::::!!*@SB#*:::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::*&[email protected]!::::::::::::::::::::::::::::::::::::::::::::!*%&BB&*:::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::*@SB#%!::::::::::::::::::::::::::::::::::::::!!%@[email protected]!:::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::!%&BB#$*!:::::::::::::::::::::::::::::::!*$&[email protected]*!:::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::!%&SBS&@%!!:::::::::::::::::::::!*%$&SBS#@*!::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::*%@#SBS#&@$%%****!****%%[email protected]&#SBBS&$*!::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::!*%[email protected]&#SSSSSSSSSSSSS##&$%*!:::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::!!!!!!!!!!!:::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
*/

contract Smilies is Ownable, ERC721A, ReentrancyGuard {
    uint256 public immutable maxPerAddressDuringMint;
    uint256 public immutable amountForDevs;
    uint256 public immutable collectionSize;

    enum Tier {
        OG,
        GOLD,
        SILVER
    }

    struct SaleConfig {
        uint32 publicSaleStartTime;
        uint32 allowlistMintStartTime;
        uint64 mintlistPrice;
        uint64 publicPrice;
        uint32 publicSaleKey;
    }

    struct TierConfig {
        uint8 maxTotalMint;
        address verificationAddr;
    }

    SaleConfig public saleConfig;

    mapping(Tier => TierConfig) private allowlistTierConfig;

    // metadata URI
    string private _baseTokenURI;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        uint256 amountForDevs_
    ) ERC721A("Smilies", "SMI") {
        require(
            maxBatchSize_ < collectionSize_,
            "MaxBarchSize should be smaller than collectionSize"
        );
        require(
            maxBatchSize_ < amountForDevs_,
            "MaxBatchSize_ too large. make it smaller than amountForDevs_ so dev mint is valid"
        );
        maxPerAddressDuringMint = maxBatchSize_;
        amountForDevs = amountForDevs_;
        collectionSize = collectionSize_;

        // innitialie TierConfig mapping
        allowlistTierConfig[Tier.OG].maxTotalMint = 3;
        allowlistTierConfig[Tier.GOLD].maxTotalMint = 2;
        allowlistTierConfig[Tier.SILVER].maxTotalMint = 2;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // Tiered Allowlist Mint
    // *****************************************************************************
    // Public functions
    function isAllowlistMintOn() public view returns (bool) {
        return
            saleConfig.mintlistPrice != 0 &&
            saleConfig.allowlistMintStartTime != 0 &&
            block.timestamp >= saleConfig.allowlistMintStartTime;
    }

    function allowlistMint(uint256 quantity, bytes memory signature)
        public
        payable
        callerIsUser
    {
        Tier tier = getAllowlistTier(msg.sender, signature);

        // Allowlist Mint should start
        require(isAllowlistMintOn(), "Allowlist sale has not begun yet");

        // Check allowlist mint size
        require(
            numberMinted(msg.sender) + quantity <=
                allowlistTierConfig[tier].maxTotalMint,
            "Allowlist mint more than allowed"
        );

        // For security purpose to prevent overmint
        require(
            totalSupply() + quantity <= collectionSize,
            "Reached max supply"
        );
        uint256 price = uint256(saleConfig.mintlistPrice) * quantity;
        _safeMint(msg.sender, quantity);
        refundIfOver(price);
    }

    function setAllowlistVerificationAddrs(
        address ogAddr,
        address goldAddr,
        address silverAddr
    ) public onlyOwner {
        allowlistTierConfig[Tier.OG].verificationAddr = ogAddr; // OG
        allowlistTierConfig[Tier.GOLD].verificationAddr = goldAddr; // Gold
        allowlistTierConfig[Tier.SILVER].verificationAddr = silverAddr; // Silver
    }

    function getAllowlistVerificationAddr()
        public
        view
        onlyOwner
        returns (
            address ogAddr,
            address goldAddr,
            address silverAddr
        )
    {
        return (
            allowlistTierConfig[Tier.OG].verificationAddr,
            allowlistTierConfig[Tier.GOLD].verificationAddr,
            allowlistTierConfig[Tier.SILVER].verificationAddr
        );
    }

    function setAllowlistTierMax(
        uint8 maxOG,
        uint8 maxGOLD,
        uint8 maxSilver
    ) public onlyOwner {
        allowlistTierConfig[Tier.OG].maxTotalMint = maxOG;
        allowlistTierConfig[Tier.GOLD].maxTotalMint = maxGOLD;
        allowlistTierConfig[Tier.SILVER].maxTotalMint = maxSilver;
    }

    // Internals
    function getAllowlistTier(address addr, bytes memory signature)
        internal
        view
        returns (Tier)
    {
        address tempAddr = ECDSA.recover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n40", this, addr)
            ),
            signature
        );
        if (tempAddr == allowlistTierConfig[Tier.OG].verificationAddr) {
            return Tier.OG;
        } else if (
            tempAddr == allowlistTierConfig[Tier.GOLD].verificationAddr
        ) {
            return Tier.GOLD;
        } else if (
            tempAddr == allowlistTierConfig[Tier.SILVER].verificationAddr
        ) {
            return Tier.SILVER;
        } else {
            revert AddressNotAllowlistVerified();
        }
    }

    // Public Mint
    // *****************************************************************************
    // Public Functions
    function publicSaleMint(uint256 quantity, uint256 callerPublicSaleKey)
        external
        payable
        callerIsUser
    {
        SaleConfig memory config = saleConfig;
        uint256 publicSaleKey = uint256(config.publicSaleKey);
        uint256 publicPrice = uint256(config.publicPrice);
        require(
            publicSaleKey == callerPublicSaleKey,
            "Called with incorrect public sale key"
        );

        require(isPublicSaleOn(), "Public sale has not begun yet");
        require(
            totalSupply() + quantity <= collectionSize,
            "Reached max supply"
        );
        require(
            numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
            "Reached max quantity that one wallet can mint"
        );
        _safeMint(msg.sender, quantity);
        refundIfOver(publicPrice * quantity);
    }

    function devMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= amountForDevs,
            "Too many already minted before dev mint"
        );
        require(
            quantity % maxPerAddressDuringMint == 0,
            "Can only mint a multiple of the maxBatchSize"
        );
        uint256 numChunks = quantity / maxPerAddressDuringMint;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxPerAddressDuringMint);
        }
    }

    function isPublicSaleOn() public view returns (bool) {
        require(
            saleConfig.publicSaleStartTime != 0 &&
                saleConfig.publicPrice != 0 &&
                saleConfig.publicSaleKey != 0,
            "Public Sale Time TBD..."
        );

        require(
            block.timestamp >= saleConfig.allowlistMintStartTime,
            "Public sale will not start until allowlist mint is done"
        );

        return block.timestamp >= saleConfig.publicSaleStartTime;
    }

    // Owner Controls
    function setPublicSaleKey(uint32 key) public onlyOwner {
        saleConfig.publicSaleKey = key;
    }

    // Public Views
    // *****************************************************************************
    function numberMinted(address minter) public view returns (uint256) {
        return _numberMinted(minter);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    // Contract Controls (onlyOwner)
    // *****************************************************************************
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setupNonAuctionSaleInfo(
        uint64 mintlistPriceWei,
        uint64 publicPriceWei,
        uint32 publicSaleStartTime,
        uint32 allowlistMintStartTime
    ) public onlyOwner {
        saleConfig = SaleConfig(
            publicSaleStartTime,
            allowlistMintStartTime,
            mintlistPriceWei,
            publicPriceWei,
            saleConfig.publicSaleKey
        );
    }

    // Internal Functions
    // *****************************************************************************
    function refundIfOver(uint256 price) internal {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}
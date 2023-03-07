// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@solv/v2-solidity-utils/contracts/access/AdminControl.sol";
import "@solv/v2-solidity-utils/contracts/misc/StringConvertor.sol";
import "@solv/v2-solidity-utils/contracts/misc/BokkyPooBahsDateTimeLibrary.sol";
import "@solv/v2-solidity-utils/contracts/openzeppelin/token/ERC20/ERC20Upgradeable.sol";
import "base64-sol/base64.sol";
import "./interface/IVNFTDescriptor.sol";
import "./interface/IVoucherSVG.sol";
import "./FlexibleDateVestingVoucher.sol";
import "./FlexibleDateVestingPool.sol";

contract FlexibleDateVestingVoucherDescriptor is IVNFTDescriptor, AdminControl {

    event SetVoucherSVG(
        address indexed voucher,
        address oldVoucherSVG,
        address newVoucherSVG
    );

    using StringConvertor for uint256;
    using StringConvertor for address;
    using StringConvertor for uint64[];
    using StringConvertor for uint32[];

    // FlexibleDateVestingVoucher address => VoucherSVG address
    // Value of key `0x0` is defined as default VoucherSVG
    mapping(address => address) public voucherSVGs;

    bool internal _initialized;

    function initialize(address defaultVoucherSVG_) external initializer {
        AdminControl.__AdminControl_init(_msgSender());
        setVoucherSVG(address(0), defaultVoucherSVG_);
    }

    function setVoucherSVG(address voucher_, address voucherSVG_) public onlyAdmin {
        emit SetVoucherSVG(voucher_, voucherSVGs[voucher_], voucherSVG_);
        voucherSVGs[voucher_] = voucherSVG_;
    }

    function contractURI() external view override returns (string memory) { 
        FlexibleDateVestingVoucher voucher = FlexibleDateVestingVoucher(_msgSender());
        return string(
            abi.encodePacked(
                'data:application/json;{"name":"', voucher.name(),
                '","description":"', _contractDescription(voucher),
                '","unitDecimals":"', uint256(voucher.unitDecimals()).toString(),
                '","properties":{}}'
            )
        );
    }

    function slotURI(uint256 slot_) external view override returns (string memory) {
        FlexibleDateVestingVoucher voucher = FlexibleDateVestingVoucher(_msgSender());
        FlexibleDateVestingPool pool = voucher.flexibleDateVestingPool();

        return string(
            abi.encodePacked(
                'data:application/json;{"unitsInSlot":"', voucher.unitsInSlot(slot_).toString(),
                '","tokensInSlot":"', voucher.tokensInSlot(slot_).toString(),
                '","properties":', _properties(pool, slot_),
                '}'
            )
        );
    }

    function tokenURI(uint256 tokenId_)
        external
        view
        virtual
        override
        returns (string memory)
    {
        FlexibleDateVestingVoucher voucher = FlexibleDateVestingVoucher(_msgSender());
        FlexibleDateVestingPool pool = voucher.flexibleDateVestingPool();

        uint256 slot = voucher.slotOf(tokenId_);
        FlexibleDateVestingPool.SlotDetail memory slotDetail = pool.getSlotDetail(slot);

        bytes memory name = abi.encodePacked(
            voucher.name(), ' #', tokenId_.toString(), ' - ', 
            _parseClaimType(slotDetail.claimType)
        );

        address voucherSVG = voucherSVGs[_msgSender()];
        if (voucherSVG == address(0)) {
            voucherSVG = voucherSVGs[address(0)];
        }
        string memory image = IVoucherSVG(voucherSVG).generateSVG(_msgSender(), tokenId_);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"', name, 
                            '","description":"', _tokenDescription(voucher, tokenId_, slotDetail),
                            '","image":"data:image/svg+xml;base64,', Base64.encode(bytes(image)),
                            '","units":"', voucher.unitsInToken(tokenId_).toString(),
                            '","slot":"', slot.toString(),
                            '","properties":', _properties(pool, slot),
                            '}'
                        )
                    )
                )
            );
    }

    function _contractDescription(FlexibleDateVestingVoucher voucher) 
        private 
        view
        returns (bytes memory)
    {
        string memory underlyingSymbol = ERC20Upgradeable(voucher.underlying()).symbol();

        return abi.encodePacked(
            unicode'⚠️ ', _descAlert(), '\\n\\n',
            'Flexible Date Vesting Voucher of ', underlyingSymbol, '. ',
            _descVoucher(), '\\n\\n', 
            _descProtocol()
        );
    }

    function _tokenDescription(
        FlexibleDateVestingVoucher voucher, 
        uint256 tokenId, 
        FlexibleDateVestingPool.SlotDetail memory slotDetail
    )
        private
        view
        returns (bytes memory)
    {
        string memory underlyingSymbol = ERC20Upgradeable(voucher.underlying()).symbol();

        return abi.encodePacked(
            unicode'⚠️ ', _descAlert(), '\\n\\n',
            'Flexible Date Vesting Voucher #', tokenId.toString(), ' of ', underlyingSymbol, '. ',
            _descVoucher(), '\\n\\n', 
            abi.encodePacked(
                '- Claim Type: ', _parseClaimType(slotDetail.claimType), '\\n',
                '- Latest Start Time: ', uint256(slotDetail.latestStartTime).datetimeToString(), '\\n',
                '- Term: ', _parseTerms(slotDetail.terms), '\\n',
                '- Voucher Address: ', address(voucher).addressToString(), '\\n',
                '- Pool Address: ', address(voucher.flexibleDateVestingPool()).addressToString(), '\\n',
                '- Underlying Address: ', voucher.underlying().addressToString()
            )
        );
    }

    function _descVoucher() private pure returns (string memory) {
        return "A Vesting Voucher with flexible date is used to represent a vesting plan with an undetermined start date. Once the date is settled, you will get a standard Vesting Voucher as the Voucher described.";
    }

    function _descProtocol() private pure returns (string memory) {
        return "Solv Protocol is the decentralized platform for creating, managing and trading Financial NFTs. As its first Financial NFT product, Vesting Vouchers are fractionalized NFTs representing lock-up vesting tokens, thus releasing their liquidity and enabling financial scenarios such as fundraising, community building, and token liquidity management for crypto projects.";
    }

    function _descAlert() private pure returns (string memory) {
        return "**Alert**: The amount of tokens in this Voucher NFT may have been out of date due to certain mechanisms of third-party marketplaces, thus leading you to mis-priced NFT on this page. Please be sure you're viewing on this Voucher on [Solv Protocol dApp](https://app.solv.finance) for details when you make offer or purchase it.";
    }

    function _properties(
        FlexibleDateVestingPool pool,
        uint256 slot
    ) 
        private
        view
        returns (bytes memory data) 
    {
        (bool delayTimeSuccess, bytes memory delayTimeBin) = address(pool).staticcall(
            abi.encodeWithSignature("delayTimes(uint256)", slot)
        );
        uint64 delayTime = delayTimeSuccess ? abi.decode(delayTimeBin, (uint64)) : 0;
        bytes memory delayTimePhrase = delayTimeSuccess ? 
            abi.encodePacked('","delayTime":"', uint256(delayTime).toString()) : 
            bytes("");

        FlexibleDateVestingPool.SlotDetail memory slotDetail = pool.getSlotDetail(slot);
        return 
            abi.encodePacked(
                abi.encodePacked(
                    '{"underlyingToken":"', pool.underlyingToken().addressToString(),
                    '","underlyingVesting":"', pool.underlyingVestingVoucher().addressToString(),
                    '","issuer":"', slotDetail.issuer.addressToString(), 
                    '","claimType":"', _parseClaimType(slotDetail.claimType)
                ),
                abi.encodePacked(
                    '","startTime":"', uint256(slotDetail.startTime).toString(),
                    '","latestStartTime":"', uint256(slotDetail.latestStartTime).toString(),
                    delayTimePhrase,
                    '","terms":', slotDetail.terms.uintArray2str(),
                    ',"percentages":', slotDetail.percentages.percentArray2str(),
                    '}'
                )
            );
    }

    function _parseClaimType(uint8 claimTypeInNum_) private pure returns (string memory) {
        return 
            claimTypeInNum_ == 0 ? "Linear" : 
            claimTypeInNum_ == 1 ? "OneTime" :
            claimTypeInNum_ == 2 ? "Staged" : 
            "Unknown";
    }

    function _parseTerms(uint64[] memory terms) private pure returns (string memory) {
        uint256 sum = 0;
        for (uint256 i = 0; i < terms.length; i++) {
            sum += terms[i];
        }
        return 
            string(
                abi.encodePacked(
                    (sum / 86400).toString(), ' days'
                )
            );
    }
}
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract TaipeSplitterEthereum is PaymentSplitter {
    address[] private _addresses = [
        0xCE973214cce7d61bd157c701cbe4694dDfa9dE6e,
        0xD16e8dc180c34465b17C07Fe688dC17E7767ACBc,
        0xe8089eb269dD19513EDF6f13491a62A4F84e55Db,
        0xDdd4D3A7dF9902609124781c4C9B5E7875868406,
        0x017Ea13EA5E545FFc954fe92FE2d666515415d42,
        0x450B2deC6461217b8222F989E7F447FB4bd06184,
        0x85a1D2DBF371f8EF0AaEE0C34861AB50aD0e25e5,
        0xaE6f962b55Ae4f654144c017EF9E183D7f0B1f62,
        0xb8dae2FF8d3001a3aC7067C0b370c84DD9C52602,
        0xFc27F8Af98D8cCE387f534eD5ba73D817FB78F57,
        0x0EF5c1F766772daBFb3c02f8049513E3f8d897E5,
        0xc0254d931eFFaEc6fEeEA007e85DE7a4AB2Bf9e1,
        0x6dB1C3126c8393Bb8559Fb15fb71Da7cAC71179b,
        0x4076FC54c193235Ebc56108C5c5eAB99e4c985EE,
        0xb3d6d28A982D7b16CDB45bF8b24Dbb0f714528d7,
        0xF58a06979Fa77038cA6e00aFF5416Ec1abb1031f
    ];
    uint[] private _shares = [
        1000 * 27.041,
        1000 * 13.566,
        1000 * 11.025,
        1000 * 11.025,
        1000 * 7.343,
        1000 * 4.5,
        1000 * 2,
        1000 * 2,
        1000 * 1.5,
        1000 * 0.65,
        1000 * 1.5,
        1000 * 1,
        1000 * 0.5,
        1000 * 1.5,
        1000 * 0.5,
        1000 * 14.35
    ];

    constructor() PaymentSplitter(_addresses, _shares) {}
}
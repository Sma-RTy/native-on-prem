// SPDX-License-Identifier: Apache-2.0
// Copyright © 2019 Intel Corporation

package auth

import (
	context "context"
	fmt "fmt"
	proto "github.com/golang/protobuf/proto"
	_ "github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger/options"
	_ "google.golang.org/genproto/googleapis/api/annotations"
	grpc "google.golang.org/grpc"
	math "math"
)

// Reference imports to suppress errors if they are not otherwise used.
var _ = proto.Marshal
var _ = fmt.Errorf
var _ = math.Inf

// This is a compile-time assertion to ensure that this generated file
// is compatible with the proto package it is being compiled against.
// A compilation error at this line likely means your copy of the
// proto package needs to be updated.
const _ = proto.ProtoPackageIsVersion3 // please upgrade the proto package

// Identity defines a request to obtain authentication credentials. These
// credentials would be used to further communicate with endpoint(s) that are
// protected by a form of authentication.
//
// Any strings that are annotated as "PEM-encoded" implies that encoding format
// is used, with any newlines indicated with `\n` characters. Most languages
// provide encoders that correctly marshal this out. For more information,
// see the RFC here: https://tools.ietf.org/html/rfc7468
type Identity struct {
	// A PEM-encoded certificate signing request (CSR)
	Csr                  string   `protobuf:"bytes,1,opt,name=csr,proto3" json:"csr,omitempty"`
	XXX_NoUnkeyedLiteral struct{} `json:"-"`
	XXX_unrecognized     []byte   `json:"-"`
	XXX_sizecache        int32    `json:"-"`
}

func (m *Identity) Reset()         { *m = Identity{} }
func (m *Identity) String() string { return proto.CompactTextString(m) }
func (*Identity) ProtoMessage()    {}
func (*Identity) Descriptor() ([]byte, []int) {
	return fileDescriptor_8bbd6f3875b0e874, []int{0}
}

func (m *Identity) XXX_Unmarshal(b []byte) error {
	return xxx_messageInfo_Identity.Unmarshal(m, b)
}
func (m *Identity) XXX_Marshal(b []byte, deterministic bool) ([]byte, error) {
	return xxx_messageInfo_Identity.Marshal(b, m, deterministic)
}
func (m *Identity) XXX_Merge(src proto.Message) {
	xxx_messageInfo_Identity.Merge(m, src)
}
func (m *Identity) XXX_Size() int {
	return xxx_messageInfo_Identity.Size(m)
}
func (m *Identity) XXX_DiscardUnknown() {
	xxx_messageInfo_Identity.DiscardUnknown(m)
}

var xxx_messageInfo_Identity proto.InternalMessageInfo

func (m *Identity) GetCsr() string {
	if m != nil {
		return m.Csr
	}
	return ""
}

// Credentials defines a response for a request to obtain authentication
// credentials. These credentials may be used to further communicate with
// endpoint(s) that are protected by a form of authentication.
//
// Any strings that are annotated as "PEM-encoded" implies that encoding format
// is used, with any newlines indicated with `\n` characters. Most languages
// provide encoders that correctly marshal this out. For more information,
// see the RFC here: https://tools.ietf.org/html/rfc7468
type Credentials struct {
	// An identifier for the set of credentials
	Id string `protobuf:"bytes,1,opt,name=id,proto3" json:"id,omitempty"`
	// A PEM-encoded signed certificate for the CSR
	Certificate string `protobuf:"bytes,2,opt,name=certificate,proto3" json:"certificate,omitempty"`
	// A PEM-encoded certificate chain, starting with the issuing CA and
	// ending with the root CA (inclusive)
	CaChain []string `protobuf:"bytes,3,rep,name=ca_chain,json=caChain,proto3" json:"ca_chain,omitempty"`
	// A PEM-encoded CAs to be added to the client's CA pool
	CaPool               []string `protobuf:"bytes,4,rep,name=ca_pool,json=caPool,proto3" json:"ca_pool,omitempty"`
	XXX_NoUnkeyedLiteral struct{} `json:"-"`
	XXX_unrecognized     []byte   `json:"-"`
	XXX_sizecache        int32    `json:"-"`
}

func (m *Credentials) Reset()         { *m = Credentials{} }
func (m *Credentials) String() string { return proto.CompactTextString(m) }
func (*Credentials) ProtoMessage()    {}
func (*Credentials) Descriptor() ([]byte, []int) {
	return fileDescriptor_8bbd6f3875b0e874, []int{1}
}

func (m *Credentials) XXX_Unmarshal(b []byte) error {
	return xxx_messageInfo_Credentials.Unmarshal(m, b)
}
func (m *Credentials) XXX_Marshal(b []byte, deterministic bool) ([]byte, error) {
	return xxx_messageInfo_Credentials.Marshal(b, m, deterministic)
}
func (m *Credentials) XXX_Merge(src proto.Message) {
	xxx_messageInfo_Credentials.Merge(m, src)
}
func (m *Credentials) XXX_Size() int {
	return xxx_messageInfo_Credentials.Size(m)
}
func (m *Credentials) XXX_DiscardUnknown() {
	xxx_messageInfo_Credentials.DiscardUnknown(m)
}

var xxx_messageInfo_Credentials proto.InternalMessageInfo

func (m *Credentials) GetId() string {
	if m != nil {
		return m.Id
	}
	return ""
}

func (m *Credentials) GetCertificate() string {
	if m != nil {
		return m.Certificate
	}
	return ""
}

func (m *Credentials) GetCaChain() []string {
	if m != nil {
		return m.CaChain
	}
	return nil
}

func (m *Credentials) GetCaPool() []string {
	if m != nil {
		return m.CaPool
	}
	return nil
}

func init() {
	proto.RegisterType((*Identity)(nil), "openness.auth.Identity")
	proto.RegisterType((*Credentials)(nil), "openness.auth.Credentials")
}

func init() { proto.RegisterFile("auth.proto", fileDescriptor_8bbd6f3875b0e874) }

var fileDescriptor_8bbd6f3875b0e874 = []byte{
	// 497 bytes of a gzipped FileDescriptorProto
	0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0xff, 0x7c, 0x92, 0x41, 0x6f, 0xd3, 0x30,
	0x14, 0xc7, 0x95, 0x96, 0x6d, 0x9d, 0x0b, 0xd3, 0x64, 0x09, 0x56, 0xa2, 0x1e, 0xac, 0xc0, 0x61,
	0x2a, 0x34, 0x6e, 0xcb, 0x4e, 0xe5, 0x42, 0x56, 0xf5, 0x50, 0x34, 0xa1, 0xaa, 0x15, 0x17, 0x2e,
	0x93, 0xeb, 0xbc, 0x25, 0x86, 0xd4, 0x36, 0xb6, 0xc3, 0x04, 0x07, 0x0e, 0x7c, 0x83, 0x8d, 0x0f,
	0xc1, 0x07, 0xe2, 0xcc, 0x8d, 0x03, 0x17, 0xbe, 0x03, 0x72, 0x08, 0xa2, 0x30, 0x6d, 0xa7, 0x38,
	0xef, 0xf7, 0xcb, 0x7b, 0x2f, 0x7f, 0x19, 0x21, 0x56, 0xba, 0x3c, 0xd6, 0x46, 0x39, 0x85, 0xef,
	0x28, 0x0d, 0x52, 0x82, 0xb5, 0xb1, 0x2f, 0x86, 0xdd, 0x4c, 0xa9, 0xac, 0x00, 0xca, 0xb4, 0xa0,
	0x4c, 0x4a, 0xe5, 0x98, 0x13, 0x4a, 0xda, 0xdf, 0x72, 0xf8, 0xb8, 0x7a, 0xf0, 0x7e, 0x06, 0xb2,
	0x6f, 0xcf, 0x59, 0x96, 0x81, 0xa1, 0x4a, 0x57, 0xc6, 0x55, 0x3b, 0xea, 0xa2, 0xd6, 0x2c, 0x05,
	0xe9, 0x84, 0x7b, 0x8f, 0xf7, 0x51, 0x93, 0x5b, 0xd3, 0x09, 0x48, 0x70, 0xb8, 0xbb, 0xf0, 0xc7,
	0xc8, 0xa2, 0xf6, 0xc4, 0x40, 0xc5, 0x59, 0x61, 0xf1, 0x1e, 0x6a, 0x88, 0xb4, 0xe6, 0x0d, 0x91,
	0x62, 0x82, 0xda, 0x1c, 0x8c, 0x13, 0x67, 0x82, 0x33, 0x07, 0x9d, 0x46, 0x05, 0x36, 0x4b, 0xf8,
	0x3e, 0x6a, 0x71, 0x76, 0xca, 0x73, 0x26, 0x64, 0xa7, 0x49, 0x9a, 0x87, 0xbb, 0x8b, 0x1d, 0xce,
	0x26, 0xfe, 0x15, 0x1f, 0xa0, 0x1d, 0xce, 0x4e, 0xb5, 0x52, 0x45, 0xe7, 0x56, 0x45, 0xb6, 0x39,
	0x9b, 0x2b, 0x55, 0x8c, 0x7e, 0x06, 0xa8, 0x9d, 0x94, 0x2e, 0x5f, 0x82, 0x79, 0x27, 0x38, 0xe0,
	0x6f, 0x01, 0xc2, 0x0b, 0x78, 0x5b, 0x82, 0x75, 0x9b, 0xcb, 0x1c, 0xc4, 0xff, 0xa4, 0x12, 0xff,
	0xf9, 0x8d, 0x30, 0xfc, 0x0f, 0x6c, 0x7c, 0x14, 0x5d, 0x04, 0x97, 0xc9, 0xc7, 0x30, 0xaa, 0xdb,
	0x11, 0xcf, 0x3d, 0xe2, 0x55, 0x26, 0x84, 0xff, 0x35, 0x9f, 0x3f, 0x42, 0xcd, 0xd1, 0x60, 0x88,
	0x1f, 0xa2, 0x28, 0xb9, 0x56, 0xf2, 0x67, 0xe6, 0x20, 0xf5, 0xf2, 0xd1, 0xe0, 0xc8, 0xcb, 0x75,
	0x67, 0x48, 0x89, 0xa8, 0xf7, 0x21, 0x52, 0x39, 0xf2, 0x46, 0xaa, 0x73, 0x49, 0xcf, 0x54, 0x29,
	0xd3, 0x4f, 0x5f, 0xbf, 0x7f, 0x6e, 0xa0, 0x68, 0x8b, 0xfa, 0xe1, 0xe3, 0xa0, 0x77, 0x7c, 0xd1,
	0xb8, 0x4c, 0x7e, 0x04, 0xf8, 0x4b, 0x80, 0x5a, 0x7e, 0x14, 0x49, 0xe6, 0xb3, 0xe8, 0x18, 0xa1,
	0xe5, 0x9a, 0x19, 0x47, 0xa6, 0x69, 0x06, 0xb8, 0x9b, 0x09, 0x97, 0x97, 0xab, 0x98, 0xab, 0x35,
	0xb5, 0xbe, 0x0c, 0x69, 0x06, 0x6b, 0xe0, 0x55, 0x8b, 0xf0, 0x9e, 0x2d, 0xb5, 0x56, 0xc6, 0x3d,
	0xab, 0x50, 0xdf, 0x33, 0x6f, 0xf6, 0xe6, 0x08, 0x27, 0x9a, 0xf1, 0x1c, 0xc8, 0x28, 0x1e, 0x90,
	0x13, 0xc1, 0x41, 0x5a, 0xc0, 0xe3, 0xdc, 0x39, 0x6d, 0xc7, 0x94, 0x5e, 0xd7, 0xd3, 0xf2, 0x1c,
	0xd6, 0x8c, 0xae, 0x0a, 0xb5, 0xa2, 0x6b, 0x66, 0x1d, 0x18, 0x7a, 0x32, 0x9b, 0x4c, 0x5f, 0x2c,
	0xa7, 0xa3, 0xad, 0x61, 0x3c, 0x88, 0x07, 0xbd, 0x20, 0x18, 0xed, 0x33, 0xad, 0x8b, 0x3a, 0x11,
	0xfa, 0xda, 0x2a, 0x39, 0xbe, 0x52, 0x59, 0xdc, 0xf5, 0xa1, 0x0c, 0xf1, 0x1e, 0xba, 0xfd, 0x52,
	0xfa, 0x45, 0x95, 0x11, 0x1f, 0x20, 0x7d, 0xf5, 0xe0, 0xe6, 0xc1, 0x4f, 0xbd, 0xba, 0xda, 0xae,
	0x6e, 0xe7, 0x93, 0x5f, 0x01, 0x00, 0x00, 0xff, 0xff, 0xb0, 0x0c, 0x90, 0xc7, 0x06, 0x03, 0x00,
	0x00,
}

// Reference imports to suppress errors if they are not otherwise used.
var _ context.Context
var _ grpc.ClientConn

// This is a compile-time assertion to ensure that this generated file
// is compatible with the grpc package it is being compiled against.
const _ = grpc.SupportPackageIsVersion4

// AuthServiceClient is the client API for AuthService service.
//
// For semantics around ctx use and closing/ending streaming RPCs, please refer to https://godoc.org/google.golang.org/grpc#ClientConn.NewStream.
type AuthServiceClient interface {
	RequestCredentials(ctx context.Context, in *Identity, opts ...grpc.CallOption) (*Credentials, error)
}

type authServiceClient struct {
	cc *grpc.ClientConn
}

func NewAuthServiceClient(cc *grpc.ClientConn) AuthServiceClient {
	return &authServiceClient{cc}
}

func (c *authServiceClient) RequestCredentials(ctx context.Context, in *Identity, opts ...grpc.CallOption) (*Credentials, error) {
	out := new(Credentials)
	err := c.cc.Invoke(ctx, "/openness.auth.AuthService/RequestCredentials", in, out, opts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

// AuthServiceServer is the server API for AuthService service.
type AuthServiceServer interface {
	RequestCredentials(context.Context, *Identity) (*Credentials, error)
}

func RegisterAuthServiceServer(s *grpc.Server, srv AuthServiceServer) {
	s.RegisterService(&_AuthService_serviceDesc, srv)
}

func _AuthService_RequestCredentials_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(Identity)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(AuthServiceServer).RequestCredentials(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: "/openness.auth.AuthService/RequestCredentials",
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(AuthServiceServer).RequestCredentials(ctx, req.(*Identity))
	}
	return interceptor(ctx, in, info, handler)
}

var _AuthService_serviceDesc = grpc.ServiceDesc{
	ServiceName: "openness.auth.AuthService",
	HandlerType: (*AuthServiceServer)(nil),
	Methods: []grpc.MethodDesc{
		{
			MethodName: "RequestCredentials",
			Handler:    _AuthService_RequestCredentials_Handler,
		},
	},
	Streams:  []grpc.StreamDesc{},
	Metadata: "auth.proto",
}

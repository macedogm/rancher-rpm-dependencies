# spec file for package k9s
#

Name:           k9s
Version:        0.27.4
Release:        0
Summary:        K9s - Kubernetes CLI To Manage Your Clusters In Style!
License:        Apache-2.0
URL:            https://k9scli.io/
Source0:        %{name}-%{version}.tar.xz
Source1:        vendor.tar.xz
BuildRequires:  go

%description
K9s provides a terminal UI to interact with your Kubernetes clusters. The aim of this project is to make it easier to navigate, observe and manage your applications in the wild. K9s continually watches Kubernetes for changes and offers subsequent commands to interact with your observed resources.

%prep
%setup -q
%setup -q T -D -a 1

%build
CGO_ENABLED=0 go build \
    -ldflags '-w -s -extldflags "-static"' \
    -mod=vendor \
    -o %{name} main.go

%install
install -D -m 0755 %{name} "%{buildroot}/%{_bindir}/%{name}"

%files
%doc README.md
%license LICENSE
%{_bindir}/%{name}

%changelog

